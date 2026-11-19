// Starts a program suspended and kills it before it runs an instruction (spec 025, R14). On macOS the system checks a new
// program the first time it is started; this takes that wait out of the timed run. Used by llm-sandbox.sh --prime.
//   llm-prime <program> [args...]   exits 0 when the program was started and reaped, 1 otherwise.
#include <signal.h>
#include <spawn.h>
#include <stdio.h>
#include <sys/wait.h>

extern char** environ;

int main(int argc, char** argv) {
    if (argc < 2) { fprintf(stderr, "usage: llm-prime <program> [args...]\n"); return 1; }
    posix_spawnattr_t attr;
    if (posix_spawnattr_init(&attr) != 0) return 1;
    if (posix_spawnattr_setflags(&attr, POSIX_SPAWN_START_SUSPENDED) != 0) return 1;  // macOS only
    pid_t pid;
    int e = posix_spawn(&pid, argv[1], NULL, &attr, argv + 1, environ);
    if (e != 0) { fprintf(stderr, "llm-prime: posix_spawn %s: error %d\n", argv[1], e); return 1; }
    kill(pid, SIGKILL);
    int st;
    if (waitpid(pid, &st, 0) != pid) return 1;
    return WIFSIGNALED(st) && WTERMSIG(st) == SIGKILL ? 0 : 1;
}
