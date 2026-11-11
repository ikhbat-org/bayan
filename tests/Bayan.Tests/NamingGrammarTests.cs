using Bayan.Semantics;
using Bayan.Syntax.Diagnostics;

namespace Bayan.Tests;

/// <summary>The project dictionary of <c>package.byn</c> as <c>Naming.GrammarOf</c> reads it.</summary>
public sealed class NamingGrammarTests : IDisposable
{
    private readonly string _dir = Directory.CreateTempSubdirectory("bayan-grammar-").FullName;

    public void Dispose()
    {
        var manifest = Path.Combine(_dir, "package.byn");
        if (File.Exists(manifest) && !OperatingSystem.IsWindows()) File.SetUnixFileMode(manifest, UnixFileMode.UserRead | UnixFileMode.UserWrite);
        Directory.Delete(_dir, recursive: true);
    }

    private string Render()
    {
        var path = Path.Combine(_dir, "main.byn");
        File.WriteAllText(path, "public struct Order {\n    public List<string> item\n}\n\nprint(\"ok\")\n");
        var c = Compilation.Create([Golden.Load(path)], _dir, new CompilationOptions());
        return DiagnosticRenderer.RenderAll(c.Diagnostics.Items, includePath: false);
    }

    [Fact]
    public void AnUnreadablePackageIsAnEmptyGrammar()
    {
        if (OperatingSystem.IsWindows()) return;
        var manifest = Path.Combine(_dir, "package.byn");
        File.WriteAllText(manifest, "");
        var empty = Render();
        Assert.Contains("BYN5104", empty);
        File.SetUnixFileMode(manifest, UnixFileMode.None);
        try { _ = File.ReadAllBytes(manifest); return; } // root reads it anyway
        catch (UnauthorizedAccessException) { }
        Assert.Equal(empty, Render());
    }

    /// <summary>User builds skip the standard library for BYN5104 to BYN5107 (Q1191); compiled as an ordinary package here, where they run, it has none.</summary>
    [Fact]
    public void StdSourcesAreCleanOfTheNamingLints()
    {
        var modules = Directory.GetDirectories(Path.Combine(Golden.RepoRoot, "lib", "std"));
        Assert.NotEmpty(modules);
        foreach (var dir in modules)
        {
            var c = Compilation.FromPath(dir, new CompilationOptions(), wholeDirectory: true);
            Assert.Contains(c.Modules, m => !m.Directory.StartsWith("<std>/", StringComparison.Ordinal));
            var hits = c.Diagnostics.Items.Where(d => d.Code is "BYN5104" or "BYN5105" or "BYN5106" or "BYN5107").ToList();
            Assert.True(hits.Count == 0, DiagnosticRenderer.RenderAll(hits, includePath: true));
        }
    }
}
