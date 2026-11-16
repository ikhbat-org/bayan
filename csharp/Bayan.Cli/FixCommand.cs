using Bayan.Semantics;
using Bayan.Syntax.Diagnostics;
using Bayan.Syntax.Parsing;
using Bayan.Syntax.Text;

namespace Bayan.Cli;

/// <summary>
/// <c>bayan fix [paths…]</c>: applies the fix of every style lint (BYN1072–BYN1080), whatever its severity in <c>lints</c>.
/// Overlapping fixes wait for the next pass, up to <see cref="Format.MaxPasses"/>. It does not run the formatter.
/// </summary>
internal static class FixCommand
{
    public static int Run(string[] args, TextWriter stdout, TextWriter stderr)
    {
        if (args.Any(a => a.StartsWith('-')))
        {
            stderr.WriteLine(Messages.CommandUsage.Text("bayan fix [<path>…]"));
            return CliApp.ExitUsage;
        }
        var paths = args.Length == 0 ? ["."] : args;
        foreach (var path in paths)
        {
            if (Directory.Exists(path) || File.Exists(path)) continue;
            stderr.WriteLine(Messages.NotFound.Text(path));
            return CliApp.ExitUsage;
        }
        var exit = CliApp.ExitOk;
        var files = new SortedSet<string>(StringComparer.Ordinal);
        foreach (var path in paths)
        {
            if (Directory.Exists(path)) files.UnionWith(Format.BynFiles(path, stderr, ref exit, Format.RealPath(path)));
            else files.Add(path);
        }
        // A file named twice (`dup ./dup`, `. src`) is fixed once: a second copy would apply the fixes found before the first rewrote it.
        var reals = new HashSet<string>(StringComparer.Ordinal);
        foreach (var module in files.Where(f => Path.GetFileName(f) != "package.byn" && reals.Add(Format.RealPath(f))).GroupBy(f => Path.GetDirectoryName(Path.GetFullPath(f))!))
        {
            try
            {
                if (!FixModule(module.Key, [.. module], stdout, stderr)) exit = CliApp.ExitFailure;
            }
            catch (Exception e) when (e is IOException or UnauthorizedAccessException)
            {
                stderr.WriteLine(Messages.FormatIoError.Text(module.Key, e.Message));
                exit = CliApp.ExitFailure;
            }
        }
        return exit;
    }

    /// <summary>
    /// Fixes the files of one module until no fix applies, then prints each changed file's count. As <c>bayan format</c>, a file with a
    /// blocking parse error is not fixed and its errors are rendered, and a pass whose fixed bytes no longer parse is abandoned for that
    /// file; false when either happened.
    /// </summary>
    private static bool FixModule(string dir, List<string> files, TextWriter stdout, TextWriter stderr)
    {
        var counts = files.ToDictionary(f => f, _ => 0, StringComparer.Ordinal);
        var refused = new HashSet<string>(StringComparer.Ordinal);
        static List<Diagnostic> Blocking(SyntaxTree tree) => [.. tree.Diagnostics.Where(d => d.IsError && !Format.InputForms.Contains(d.Code))];
        for (var pass = 0; pass < Format.MaxPasses; pass++)
        {
            var typed = TypedFixes(dir);
            var changed = false;
            foreach (var file in files.Where(f => !refused.Contains(f)))
            {
                var real = Format.RealPath(file);
                var bytes = File.ReadAllBytes(real);
                var tree = SyntaxTree.Parse(new SourceText(file, bytes));
                if (Blocking(tree) is { Count: > 0 } blocking)
                {
                    stderr.Write(DiagnosticRenderer.RenderAll(blocking, includePath: true));
                    refused.Add(file);
                    continue;
                }
                var fixes = tree.StyleLints.Select(d => d.Fix).Concat(typed.GetValueOrDefault(real) ?? []).OfType<Fix>().ToList();
                if (fixes.Count == 0) continue;
                var fixedBytes = Format.ApplyFixes(bytes, fixes, out var applied);
                if (Format.RewriteHook is not null) fixedBytes = Format.RewriteHook(fixedBytes);
                if (fixedBytes.AsSpan().SequenceEqual(bytes)) continue;
                if (Blocking(SyntaxTree.Parse(new SourceText(file, fixedBytes))).Count > 0)
                {
                    stderr.WriteLine(Messages.FormatRewriteAbandoned.Text(file));
                    refused.Add(file);
                    continue;
                }
                Format.WriteReplacing(real, fixedBytes);
                counts[file] += applied;
                changed = true;
            }
            if (!changed) break;
        }
        foreach (var (file, count) in counts.Where(c => c.Value > 0))
            stdout.WriteLine(Messages.FixFixed.Text(file, count));
        return refused.Count == 0;
    }

    /// <summary>
    /// The fixes of the lints that need types (BYN1078, and BYN1080 on a local), by full path, from a compilation of the module
    /// with tests. Imports resolve under the first root that compiles cleanly: a project's <c>src/</c>, then the module's
    /// directory and its two parents; otherwise under the one with the fewest errors.
    /// </summary>
    private static Dictionary<string, List<Fix?>> TypedFixes(string dir)
    {
        var sources = Directory.EnumerateFiles(dir, "*.byn").Where(f => Path.GetFileName(f) != "package.byn").Order(StringComparer.Ordinal)
            .Select(f => SourceText.FromFile(Format.RealPath(f))).ToList();
        Compilation? best = null;
        foreach (var root in Roots(dir))
        {
            var c = Compilation.Create(sources, root, new CompilationOptions(true));
            if (best is null || ErrorCount(c) < ErrorCount(best)) best = c;
            if (ErrorCount(c) == 0) break;
        }
        var fixes = new Dictionary<string, List<Fix?>>(StringComparer.Ordinal);
        foreach (var d in best?.StyleLints ?? [])
            if (d.Source is { } source)
                (fixes.TryGetValue(source.Path, out var list) ? list : fixes[source.Path] = []).Add(d.Fix);
        return fixes;
    }

    private static int ErrorCount(Compilation c) => c.Diagnostics.Items.Count(d => d.IsError);

    private static IEnumerable<string> Roots(string dir)
    {
        for (var up = Path.GetDirectoryName(dir); up is not null; up = Path.GetDirectoryName(up))
        {
            var src = Path.Combine(up, "src");
            if (File.Exists(Path.Combine(up, "package.byn")) && dir.StartsWith(src + Path.DirectorySeparatorChar, StringComparison.Ordinal))
            {
                yield return src;
                break;
            }
        }
        for (var (up, i) = (dir, 0); up is not null && i < 3; up = Path.GetDirectoryName(up), i++)
            yield return up;
    }
}
