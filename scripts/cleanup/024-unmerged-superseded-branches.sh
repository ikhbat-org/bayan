#!/usr/bin/env bash
# Cleanup after the 0.4.0 cut (written 2026-11-24): branches not merged into dev whose work dev already holds in another
# form, or that are obsolete scratch, plus their worktrees. Produced by the branch triage in tmp/inv-*.sh that day:
#   - 59 branches: every commit has a patch-equivalent on dev (`git cherry dev <b>` prints no '+');
#   - 33 more: every unique commit has a same-subject commit on dev, or is in chore/019-export (pre-2026-11-14-rewrite
#     copies; several carry Claude-authored commits, so they must never be merged into dev, not even with -s ours);
#   - the rest: probes, break-test scratch, restack backups, worker reports, C#-era mutation work, the unsplit 0.4.0 cut.
# Kept and not listed: dev, main, chore/019-export (FREEZE.tsv's export row), feat/025-llm-eval-set and fix/llm-eval-timing
# (being merged), chore/worker-019-decisions, feat/019-workflows, chore/019-t67-cinventory-no-csharp (owner to look at).
# Each branch is checked at run time: it must still point at the sha recorded here (a moved branch is left alone).
# Before a branch is deleted its tip is saved as refs/archive/<branch> (not pushed by default), so
#   git branch <branch> refs/archive/<branch>
# restores it. A worktree holding a target branch is removed first with `git worktree remove` (refuses a dirty tree; then
# the branch stays too). The branch the main checkout is on is never deleted.
# Dry run by default. --execute / -e removes the worktrees; --delete-unmerged-branches also deletes the branches
# (git branch -D: they are not merged into dev, which is the point).
set -euo pipefail

execute=0; delete=0
for a in "$@"; do
  case "$a" in
    --execute|-e) execute=1 ;;
    --delete-unmerged-branches) delete=1 ;;
    *) printf 'unknown flag: %s\n' "$a"; exit 2 ;;
  esac
done
repo="$(git rev-parse --show-toplevel)"
cd "$repo"
failed=0; gone=0; done_n=0; kept=0

if [ "$(git branch --show-current)" != "dev" ]; then
  printf 'refuse: run from the dev worktree (on %s).\n' "$(git branch --show-current)"; exit 1
fi
main="$(git rev-parse --path-format=absolute --git-common-dir)"; main="${main%/.git}"
main_branch="$(git -C "$main" branch --show-current)"

# worktree_of BRANCH: the path of the worktree that has BRANCH checked out, empty when none.
worktree_of() {
  git worktree list --porcelain | awk -v b="refs/heads/$1" '/^worktree /{w=substr($0,10)} $0=="branch " b {print w}'
}

printf '== superseded branches\n'
while read -r b sha; do
  [ -n "$b" ] || continue
  if ! cur="$(git rev-parse --verify --quiet "refs/heads/$b")"; then
    printf 'skip:  %s no longer exists\n' "$b"; gone=$((gone+1)); continue
  fi
  if [ "$cur" != "$sha" ]; then
    printf 'keep:  %s moved (%s, recorded %s)\n' "$b" "${cur:0:9}" "${sha:0:9}"; kept=$((kept+1)); continue
  fi
  if [ "$b" = "$main_branch" ]; then
    printf 'keep:  %s is checked out in the main checkout; switch it first\n' "$b"; kept=$((kept+1)); continue
  fi
  wt="$(worktree_of "$b")"
  if [ -n "$wt" ]; then
    if [ -n "$(git -C "$wt" status --porcelain 2>/dev/null)" ]; then
      printf 'keep:  %s (worktree %s has changes)\n' "$b" "${wt#"$main"/}"; kept=$((kept+1)); continue
    fi
    if [ $execute = 1 ]; then
      if git worktree remove "$wt"; then printf 'done:  worktree %s removed\n' "${wt#"$main"/}"
      else printf '  refused: worktree %s not removed. Left alone.\n' "${wt#"$main"/}"; failed=1; continue; fi
    else
      printf 'would: git worktree remove %s\n' "${wt#"$main"/}"
    fi
  fi
  if [ $delete = 1 ] && [ $execute = 1 ]; then
    git update-ref "refs/archive/$b" "$sha"
    if git branch -D "$b" > /dev/null; then printf 'done:  %s deleted (refs/archive/%s)\n' "$b" "$b"; done_n=$((done_n+1))
    else printf '  refused: %s not deleted.\n' "$b"; failed=1; fi
  else
    printf 'would: archive and delete %s (%s)\n' "$b" "${sha:0:9}"
  fi
done <<'LIST'
backup/t19a-restack fc760a16acff2c9bb93321f4094074f6d9dc3578
backup/t19b-restack 5def8ede02df96b33df19f0cebd4a6090716f1e8
chore/015-merge-dev 76ff2a5f8f747b189bb21aed266a9857caf3185b
chore/015-t8 2507d205e619987abcea19d8783e484843803cdc
chore/017-preflight-sh 6176d2f9c9f13ab055de4b43caaf0c28931f35f5
chore/017-t11-refusal-tests ed5804bbc254a1440a58d1f9cc6d8f72ce4a3f26
chore/go-trial b2d40362c0fd95abd744209e37e7eb81bad9f8f9
chore/pages-on-main be206ed355370108d3eb88f0855d4e887c3c6975
chore/q31-bt-frontend-off 9c1320ef7b28c9d987c56d9c8db3864639678c5c
chore/q31-bt-region-off 05311ed87afb762635a3bbe2ce5f31515fac9a76
chore/q31-bt-summary-off f44a60b0f62c71ef8eacba2fea8b476b56fc038a
chore/release-0.4.0 f0db09657a0f3ad2e549f2f30ba53bbd29a2eda7
chore/t13-probe c5638d7fb4f8f2c223c87f8fe36aaf9427c99aa9
chore/worker-007b 8f78edd6737be081da0567a6b24a0406f941a44c
chore/worker-011-p2 153f1f746ed2808cade1ee2aefa0460f02f96d56
chore/worker-012-t16 9a68198cc2ffaf27980fb27921a4383445db974f
chore/worker-014-t3 28ecfa538c0a6d54e5874ae65431d281370bdeaa
chore/worker-015-t5 c607077412ca741514bf5cc5afc07ad556c13e82
chore/worker-015-t7 876aa4722e82d066414ed34dd71e8948349d9b77
chore/worker-015-t8 26e84e26396f0be6c016b69152054e488adb3939
chore/worker-017-q1106 8acff219851d35a152fe6b4ebdb78235104fb109
chore/worker-017-t11 7e907cf8f2d7c9e5379674f9ade4511bbe9a4eee
chore/worker-017-t12 734cc8f3a659ab11179de20690d19758d3f10bc1
chore/worker-017-t13 1a15b95f812b23d2b54900c8d39906000f995f69
chore/worker-017-t14 8a7ea54e9de52b5fc6aedf9893a319e1167e208f
chore/worker-017-t14b 2b2752b6ffd3ca7daa9e092c613b16b85dd49707
chore/worker-017-t15 2006528d356dcdc60e1c26eec1197933a0fbf738
chore/worker-017-t16 02773ca6929ac1f71955ce7ce8434e28163a60b8
chore/worker-017-t17 7e1e66c357ae82360642a5ffc1f96db0bb16f725
chore/worker-017-t18 638a667343fd7f9a3e147ef89d89fd37c3eab958
chore/worker-017-t9b 51d0f40e2a1219963346dc0f7d6621ba2a000aea
chore/worker-019-t13 8ef29b473cd20025f32443d34da396f36df90244
chore/worker-019-t13b 6f801bda873a4ccbdeec6751a2e0add9811d4107
chore/worker-019-t13c 60f04e5989e07c9ae0fdb8c548980c770c06a76e
chore/worker-019-t14 890b7a215747c47dadde4f97fa373a1ce739409d
chore/worker-019-t15 984aa479d5e5e9833402cf9975a43a956333145b
chore/worker-019-t15a 3d965fa010cce2185da96a5042858a54b09078dc
chore/worker-019-t15bd 50c3f268f68fe7bb24f23ce76d929554ffcb905c
chore/worker-019-t15c 1d8f01eb14361f96ed534dcdccb2c0f24f319802
chore/worker-019-t15ef 491343056eec927caab86db307ca8f3049f6d25e
chore/worker-019-t15g d4af73ca019a2d48a0c30d13a62ba681ac89566b
chore/worker-019-t16ad 65cc85c3b26197c9fcf9072f01cc16d1520fba4a
chore/worker-019-t16bc 93c2976780476d9f0712a2ab6d4f491929c5e3f0
chore/worker-019-t16e 708862662f17de2bafa8ae9d20aa4b50109dd271
chore/worker-019-t17c b34eefc130738e47333761f7e075416fffc94022
chore/worker-019-t17x 5544e5d2a383883673fb0a596d491c421f1adc44
chore/worker-019-t19x f747817a5522313b73aa09f17658f916847c7034
chore/worker-019-t24b-export ad1cbefa62cd27ecd0ffee6a84483a736638d0fc
chore/worker-019-t26w cfbefaf5c8a84e50e2200297708d5e3c7c4a0f0d
chore/worker-019-t26x 08d4cdb1433cd981a9a68a361aafca5dba9199c2
chore/worker-019-t26x2 6286d4faa8d6dec4b2de920d74f11c5fe8f3f5a7
chore/worker-019-t28x 32fd29d44f696ecbbac72a5c7859712d72d663c0
chore/worker-019-t30ba 44b718d09fc6b974946a5257cd5e26b62962958f
chore/worker-019-t30bc 9d782e07da6f43378b0d799146b4be66608a2f90
chore/worker-019-t30fa 982be52420193932edc68fb8b0ff54a78d1a3e8f
chore/worker-019-t31ba 588754015409772c0ddce45a8804433c94654faa
chore/worker-019-t43 59344f7fea8e2603d839de5a9e095e82c33e2845
chore/worker-019-t44b 9d53b1d3f9358182a67c2b5fa83b6b7089d2dfc7
chore/worker-025-t45 29a847327ba1b0c099f29de8d54216c884f93d85
chore/worker-by-t1 399ec736c70a456ac021569abec749eb32299cb5
chore/worker-by-t2 bc45f409ecf9084bf12b639f35b1095f39396494
chore/worker-mut-perfn b3da354c12c2f040a442f154a7ffd115398bbc45
chore/worker-mut-schemata-progress dc4f27ee42c48e45f243e5d4a0b2d427d86ae1b6
chore/worker-p007-a1 98c12a3fbc7fc4d0160c0ca989f88611e09d75ce
chore/worker-p007-a2 eb95ad33484f92a0da705e071dbba8665f7d9c8d
chore/worker-p4-followup e7ed3ec8c9fe169bb797aefd435da6b38b893736
chore/worker-q1190 e0a115863487d9a37a411fea4fb3e6c8ce60d246
chore/worker-rev-0022 1a0f6db6105b3da7d215c78844ce9c66763058e2
chore/worker-rev-caps c3cdce447d7aecadbd400f066debdb65a2cd7c80
chore/worker-rev21-report ca8a2eed651e74f1f8bcac14a189bd266e89abf8
chore/worker-rv-007b e77b7f04b12d3fd1cebaeb5fcb4dad08d6c9636b
chore/worker-rv-007b2 2e1268da442f094eff6c15cb781864f188de39d2
chore/worker-rv-e764-signaled 47f4d3dd5319e11df26f53942e3e701a43d4e78e
chore/worker-shard-v2 6303f6c422713f3132504fff479d5b83995bc67f
chore/worker-shard-v2-fix bba963711552bbe91801b632d89cdf184426a303
chore/worker-spec-020 f9e3bd257e4c996d95d5cce979b5d5f5e0498eb7
chore/worker-std-time-1a 7370c4e85d1ac4dcad7dc8c4d0f510faa408785a
chore/worker-std-time-1a-fix 6b5783ec11305ca3ce86c7e64467bcb6c0e0bb46
docs/020-tasks e45accc8febac9086d5e2267e57e6da97c9e59c2
docs/freeze-concurrency-codes 1f0238bb5445bc05ee4e9cbf1c82e7bcad6ebdea
docs/main-readme d1e3bfff7cc635553bde7aa2094963422dc51f7f
docs/rev-0022-contract-hardening 59ce0f7e1a70ec9dd84340800dbab0717045e126
docs/sabk-name a362b31e734c226e4ec4012041cfc0eb8dfdb889
docs/std-time-1a 22e722d3227a7dc5d8e98bb93f9a65a8ae38a7bb
feat/007-io-run-phase-b 3934df3ffc575950a3df8dfa84c5e6913a2e685d
feat/007-io-run-status 90c4d24227e3dd7572ccf0e215deca3b634729dc
feat/009-prebuilt-runtime-object 49090796931592242c6c94031ad8c29520671f3d
feat/011-self-hosted-emitter b34eefc130738e47333761f7e075416fffc94022
feat/015-tooling-ports 6b4f494534b4ce1fbd1d7bf6e49b609dde0c7532
feat/017-selfhost-default 2d9d367080776c598a7047a4ac0769c1ef773e98
fix/017-full-suite 95a1e837a63251f01d53343406b044f92b0b1735
fix/017-preflight-yml 29e079b73f850719573611932c4d9732b7f099f7
fix/018-part4-followup 471207489cad70bd6c3903d134fb897c855922ef
fix/018-std-skip-grammar 092008b2fcf07b4e43f50497260604b9ae51d22d
fix/mutate-batch-windows-paths 6782a84af725d545299704408bc416c3a7326096
fix/mutate-schemata-progress 8395114faa11590fe0b5ca0e3c070654c84cd4bb
fix/q1190-number-agreement 2412a49de8ba2cd10ed5c681d06a5b908e28b0c0
fix/release-0.3.2-l028 984aa479d5e5e9833402cf9975a43a956333145b
fix/review-2026-11-10-5 7e8b66595dbd608ee5795055b15eaf5c1561addc
fix/review-2026-11-11-3 f01de7cb5601df66c02275a013cc7ba37679388a
fix/review-2026-11-11-4 e2779a1a96202c321b3073b439060a392aebacb8
fix/shard-vm-node-reuse 4bef635d2fa37fb642618575fdc9b2a3d5eda8c4
fix/zig-trim-test-limit b3331b82b2d5c967949f72c7ed78e9dcd9f5eb33
probe/mutate-peak-linux 43d2cf8d3c466033c6f9316e41cbf84a0c920a02
test/025-t6-broken-ref ecda063d337c150ca0b5fa327f8a16f621ab8148
test/leak-integration db7150592c258423bee7e8f708210c3808774548
test/release-0.3.0-preflight b382b24604f4250a827daca0782b71d6f2e87ee6
test/release-0.3.0-preflight-2 e9f5ef68137317467568f6e57031641fffd6892d
tmp/014-probe-bad d24da811cddf4e1b41cab061fec9059b261e0be5
tmp/014-probe-ok 8055b2a2a7b8b4a9af07414b20575723885b4218
LIST
[ $execute = 1 ] && git worktree prune

printf '== remaining\n'
printf 'deleted %s, already gone %s, kept %s\n' "$done_n" "$gone" "$kept"
printf 'branches not merged into dev: %s\n' "$(git branch --no-merged dev | wc -l | tr -d ' ')"
printf 'worktrees: %s\n' "$(git worktree list | wc -l | tr -d ' ')"
[ $execute = 1 ] && [ $delete = 0 ] && printf 'branches stay: add --delete-unmerged-branches to delete them.\n'
if [ $execute = 1 ] && [ $failed = 1 ]; then exit 1; fi
exit 0
