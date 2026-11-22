# Porting notes

How rclone, Syncthing and the GitHub CLI are made to build and run on
RenkuOS/Haiku, what each patch is for, and what was checked.

## Layout

| Path | What it is |
| --- | --- |
| `build.sh` | clones a tool at its pinned tag, patches it and its dependencies, cross-builds `dist/<arch>/<binary>` |
| `package.sh` | makes `dist/<name>-<version>-<revision>-<arch>.hpkg` |
| `tools/<tool>.conf` | repository, tag, build tags, version stamps, package description |
| `tools/deps.list` | the dependencies that are swapped for a patched copy: name, module, version |
| `patches/<tool>.patch` | changes to the tool's own source |
| `patches/deps/<name>.patch` | changes to one dependency, against the version in `tools/deps.list` |
| `patches/go/` | fixes to the Go toolchains themselves |

Everything is built with `CGO_ENABLED=0`. A Go binary for Haiku is still
dynamically linked: it calls `libroot.so` and `libnetwork.so` directly, and
needs nothing else.

## Go toolchains

| Architecture | Toolchain | Patch from `patches/go/` |
| --- | --- | --- |
| arm64 | [renkuos-golang](https://github.com/rainygirl/renkuos-golang), Go 1.27.4 | `go-haiku-arm64-startup.patch` |
| x86_64 | [korli/go](https://github.com/korli/go) `golang-1.27-haiku`, Go 1.27.4 | none |
| 32-bit x86 | [renkuos-golang-x86](https://github.com/rainygirl/renkuos-golang-x86) revision 2, Go 1.26.5 | none (the fixes are in its `patches/`) |

The arm64 patch only touches the standard library, so the toolchain does not
have to be rebuilt: apply it to its tree (or to a copy) and the next
`go build` compiles the changed packages.

### arm64: `go-haiku-arm64-startup.patch`

`runtime/asm_arm64.s` in that tree still has six debugging writes in the
startup path. Every program built with it prints `234567` on stderr before
`main` runs. The patch removes them.

### 32-bit x86: renkuos-golang-x86

The 32-bit tools are built with the cross toolchain that renkuos-golang-x86's
`build.sh` leaves in `.work/go` (`bin/go` there runs on the build machine and
targets haiku/386). It is the same tree as the native `golang_x86` package:
korli/go `golang-1.26-haiku` with one haiku/386 patch series on top.

That series now also has what this repository used to carry as
`patches/go/go-haiku386-fixes.patch`, found while bringing up these tools on
a Haiku nightly (hrev60450, x86_gcc2) under QEMU:

- **Async preemption crashed** in the older tree of renkuos-rtailscale
  `i386/`: a hello world died with a segmentation violation at start unless
  run with `GODEBUG=asyncpreemptoff=1`. The old patch made that the default.
  The cause was the unversioned `sigaction` import, which binds to the
  BeOS-compatible symbol; renkuos-golang-x86 imports it by its version and
  takes the handler's `siginfo` and `ucontext` as Haiku passes them, so
  preemption stays on.
- **64-bit file offsets were passed as one word** in `Seek`, `pread`,
  `pwrite`, `Truncate`, `Ftruncate` and `mmap`. Fixed the same way in both;
  renkuos-golang-x86 also passes the high half of `mmap`'s offset.
- **sysvicall6 read words seven and eight from its result slots.** The
  runtime copies eight argument words to the C stack. `patches/deps/sys.patch`
  calls the 386 `mmap` with six words and needs the seventh (the high half of
  the offset) to be zero, so the runtime now copies the six arguments into
  an array padded with zeros (`go-haiku386-syscallargs.patch` there).
  `build.sh` refuses a 386 toolchain without it. File offsets of 4 GiB and
  more are still out of reach of `mmap` through x/sys.

## golang.org/x/sys

Upstream `golang.org/x/sys/unix` has no Haiku support at all, and most of
what these tools depend on imports it. `patches/deps/sys.patch` is, against
v0.50.0:

- the amd64 port from [korli/sys_haiku](https://github.com/korli/sys_haiku);
- the arm64 files of renkuos-golang;
- **386 files, new here** (`asm_haiku_386.s`, `syscall_haiku_386.go`,
  `zerrors_haiku_386.go`, `zsyscall_haiku_386.go`, `ztypes_haiku_386.go`).
  The struct layouts were checked against a C program compiled with the
  x86_gcc2 cross compiler and run on 32-bit Haiku: `time_t`, `long`, `rlim_t`
  and pointers are 4 bytes there, `off_t` and `ino_t` stay 8. The generated
  system call file is edited by hand for the two-word `off_t`;
- `syscall_haiku_extra.go` for all three: `Madvise`, `Mlock`, `Munlock`,
  `Msync`, `Mprotect`, `Statvfs`, `Getpgrp`, the `WNOHANG` family, and working
  `Wait4` and `Gethostname`. The last two were declared without a body in the
  port and failed at link time as soon as something used them; `Wait4` is
  `waitpid`, since libroot has no `wait4`.

A probe that exercises these calls against the kernel (stat, statvfs, uname,
pread/pwrite/lseek, ftruncate, flock, fcntl locks, mmap/madvise/msync, pipe,
poll, waitpid) gave the same, correct answers on all three architectures.

## Dependencies

All of these fail to compile for Haiku because their per-OS files do not list
it. Most patches add `haiku` to a build constraint that already covers the
other Unix systems.

| Name | Module | Change |
| --- | --- | --- |
| `afero` | github.com/spf13/afero | `EBADF` instead of Linux's `EBADFD` |
| `azblob`, `azfile` | Azure SDK storage | use the Unix memory-mapped buffer |
| `bbolt` | go.etcd.io/bbolt | `bolt_haiku.go`: `flock` through x/sys (`syscall.Flock` does not exist on Haiku) |
| `browser` | github.com/cli/browser | open URLs with Haiku's `open` |
| `bubbletea` | charm.land/bubbletea/v2 | use the Unix tty and signal code |
| `clipboard` | github.com/atotto/clipboard | read and write with Haiku's `clipboard` command |
| `cterm` | github.com/charmbracelet/x/term | terminal support, as `xterm` below |
| `ctgo` | certificate-transparency-go | system roots from `/system/data/ssl/CARootCertificates.pem` |
| `flock` | github.com/gofrs/flock | use the `flock` implementation |
| `go-diskfs` | github.com/diskfs/go-diskfs | use the Unix file property code |
| `isatty` | github.com/mattn/go-isatty | a real terminal check; upstream answers "never a terminal" on Haiku |
| `goleveldb` | github.com/syndtr/goleveldb | `file_storage_haiku.go`: `fcntl` locks, as on Solaris |
| `logrus` | github.com/sirupsen/logrus | terminal check with `TCGETA` |
| `sftp` | github.com/pkg/sftp | use the Unix stat and `ls` code |
| `survey` | github.com/AlecAivazis/survey/v2 | `runereader_haiku.go`: termios through x/sys instead of a raw `ioctl` system call |
| `tcell`, `tcell2` | github.com/gdamore/tcell v3 and v2 | Unix tty code, termios with `TCGETA`/`TCSETAW`; flushing input is best effort |
| `termenv` | github.com/muesli/termenv | termios with `TCGETA`/`TCSETA`; reads the terminal's answers in Haiku's order |
| `xdg` | github.com/adrg/xdg | use the Unix base directories |
| `xterm` | golang.org/x/term | terminal support: `IsTerminal`, raw mode, size, `ReadPassword` |

### Terminals

Haiku names the termios ioctls `TCGETA`, `TCSETA`, `TCSETAW` and `TCSETAF`;
unlike the System V calls of the same name they take a `struct termios`.

- **Without the `xterm`, `cterm` and `isatty` patches nothing is a terminal.**
  All three libraries fall back to "not a terminal, not supported" on an
  unknown system. The tools then still run, but `gh` skips every prompt and
  takes the defaults, colours are off, and rclone cannot ask for a password.
- **Haiku's Terminal answers queries out of order.** termenv asks for the
  background colour (OSC 11) and then for the cursor position, and takes a
  cursor answer arriving first to mean "no OSC support". Terminal sends the
  cursor answer first and the colour right after it; left unread, the colour
  answer was taken for typed input by the next prompt (`could not prompt:
  unexpected escape sequence`). The patch reads the late answer on Haiku.
- **`TCFLSH` fails on RenkuOS arm64** (it works on x86_64). tcell flushes
  pending input before it starts and treated the failure as fatal, so
  `rclone ncdu` did not start; the flush is now best effort.

A tool gets the version pinned in `tools/deps.list` even where its own
`go.mod` asks for a slightly different one (Syncthing 1.30.0 asks for flock
0.12.1 and x/sys 0.33.0, the GitHub CLI for logrus 1.9.4): one patch per
module rather than one per version.

## The tools

### rclone 1.76.0

`patches/rclone.patch`: stderr redirection and file metadata use the Unix
code; `rclone about` and the disk usage call go through `statvfs`;
`rclone version` reports the system from `uname`.

Not available: `rclone mount` (no FUSE the Go bindings can use), and extended
attributes on the local backend.

### Syncthing 1.30.0

Syncthing 2.x cannot be built: it stores its database in SQLite through
modernc.org/sqlite, whose C runtime, modernc.org/libc, is generated per
operating system and has no Haiku target. The other route, cgo with
mattn/go-sqlite3, needs cgo in three Haiku Go ports. 1.30.0 is the last
release on LevelDB, which is pure Go.

`patches/syncthing.patch`:

- no file watcher (github.com/syncthing/notify has no backend for Haiku's
  node monitor): folders have the watcher switched off, so Syncthing does not
  retry it every minute, and rely on the periodic rescan;
- no extended attribute sync;
- no warning about running as root: every Haiku program runs as uid 0;
- the GUI is opened with `open`;
- built with the `noupgrade` tag: there are no upstream binaries to upgrade to.

### GitHub CLI 2.100.0

`patches/gh.patch` only adds a `flock` implementation for the lock files;
the rest is in the terminal libraries above.
2.101.0 and later need Go 1.27, and the 32-bit toolchain is 1.26.5, so all
three architectures are built from 2.100.0.

## Verification

Each package was installed with `pkgman install` in a guest under QEMU and
exercised there (2026-11-22). Guests: RenkuOS arm64 live image (hrev60072,
HVF), Haiku nightly hrev60450 x86_64 and x86_gcc2 (TCG).

| Tool | Checked in the guest | arm64 | x86_64 | 32-bit x86 |
| --- | --- | --- | --- | --- |
| rclone | `version`; `copy` + `check` + `md5sum` of a 3 MB file; `sync`; `lsd` of an `:http:` remote (downloads.rclone.org, 134 entries); `serve http` on loopback, read back with wget/curl and with an `:http:` remote; `about` | pass | pass | pass |
| rclone | `ncdu` and the config password prompt in Terminal | pass | not run | not run |
| Syncthing | two instances on loopback (discovery, relays and NAT off), devices and a folder added over the REST API; a 5 MB file, a small file and a subdirectory synced A to B with identical md5, a file synced B to A, both GUIs answer, clean shutdown over REST | pass | pass | pass |
| gh | `--version`; `auth status` (not logged in); `api /zen` with a made-up token returns GitHub's 401; `completion`; `help` | pass | pass | pass |
| gh | `auth login` prompts in Terminal (arrow keys, selection) up to the one-time code; no login done | not run | pass | not run |

The 32-bit packages were rebuilt as revision 2 with the renkuos-golang-x86
revision 2 toolchain and checked again on the x86_gcc2 nightly: `version` of
all three; rclone `copy`, `check`, `md5sum` and `sync` of a 5 MB file and a
subdirectory, `lsf` of an `:http:` remote, `about`; the Syncthing test above
(A to B and B to A, both GUIs, shutdown over REST, and SIGTERM stops it);
`gh api /zen` and `gh api /user` with a made-up token return 401. All pass.

Found and not fixed:

- **arm64: Go programs ignore SIGINT and SIGTERM** (`kill` and Ctrl-C do
  nothing, with or without `signal.Notify`; `kill -9` works). Measured with a
  small program on all three: x86_64 and 32-bit x86 deliver both. A fault in
  the arm64 runtime's signal path in renkuos-golang, outside this repository.
  The READMEs say how to stop a program instead.
- **arm64: an HTTPS listing hung twice** without rclone's `--contimeout` and
  `--timeout` set (it stayed inside the request for minutes). Eight runs in a
  row with `--contimeout 10s --timeout 15s` all finished. Cause not found.

Not checked: Syncthing between two machines, or with a 2.x peer; rclone
against a remote that needs credentials; `gh` after logging in; any of it on
real hardware or on a RenkuOS x86 image.
