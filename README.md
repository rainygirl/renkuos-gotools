# Go tools for RenkuOS

English · [Italiano](README.it.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

rclone, Syncthing, the GitHub CLI, restic, Hugo, Caddy, fzf and lazygit, built
for RenkuOS (Haiku) on arm64, x86_64 and 32-bit x86. Unofficial builds, not
affiliated with any of those projects or with GitHub.

| Tool | Version | Package | Package on 32-bit x86 |
| --- | --- | --- | --- |
| rclone | 1.76.0 | `rclone` | `rclone_x86` |
| Syncthing | 1.30.0 | `syncthing` | `syncthing_x86` |
| GitHub CLI (`gh`) | 2.100.0 | `github_cli` | `github_cli_x86` |
| restic | 0.19.1 | `restic` | `restic_x86` |
| Hugo | 0.165.0 | `hugo` | `hugo_x86` |
| Caddy | 2.11.9 | `caddy` | `caddy_x86` |
| fzf | 0.75.0 | `fzf` | `fzf_x86` |
| lazygit | 0.66.3 | `lazygit` | `lazygit_x86` |

## Install with pkgman

Add the repository once, then install what you need.

| System | Repository | Example |
| --- | --- | --- |
| arm64 | `pkgman add-repo http://pkgman.rainygirl.com/arm64` | `pkgman install rclone` |
| x86_64 | `pkgman add-repo https://pkgman.rainygirl.com/x86_64` | `pkgman install rclone` |
| 32-bit x86 (x86_gcc2) | `pkgman add-repo https://pkgman.rainygirl.com/x86_gcc2` | `pkgman install rclone_x86` |

If `pkgman add-repo` fails with `Operation not supported`, the network kit of
that image has no TLS; use `http://` instead of `https://` in the address.

Each package installs one command into `/boot/system/bin`: `rclone`,
`syncthing`, `gh`, `restic`, `hugo`, `caddy`, `fzf` or `lazygit`.

## Install a package file

Without the repository, with a `.hpkg` built by `package.sh`:

```sh
pkgman install ./rclone-1.76.0-2-arm64.hpkg
```

Package revisions: on arm64, `rclone`, `syncthing` and `github_cli` are
revision 2 and the others revision 1; on 32-bit x86, `rclone_x86`,
`syncthing_x86` and `github_cli_x86` are revision 2 and the others
revision 1; on x86_64 all are revision 1. The arm64 packages are built
with the Go toolchain of golang_bin revision 10, which delivers signals.

## rclone

```sh
rclone config                # set up a remote
rclone copy ~/Documents remote:backup
```

`rclone mount` is not available: Haiku has no FUSE the Go bindings can use.
Everything else is the stock rclone. In Terminal the configuration file is
`~/config/settings/rclone/rclone.conf`.

## Syncthing

```sh
syncthing                    # then open http://127.0.0.1:8384
```

- This is the 1.x series. Syncthing 2.x keeps its database in SQLite through a
  library that has no Haiku port.
- There is no file watcher for Haiku, so a folder is picked up when it is
  rescanned. The default interval is one hour: lower *Full Rescan Interval*
  in the folder's settings if you need changes to travel sooner.
- Automatic upgrades are disabled; a new version comes as a new package.
- The package does not start Syncthing at login.

## GitHub CLI

```sh
gh auth login
```

`gh` opens web pages with Haiku's `open` command. 2.100.0 is the newest
release that the 32-bit toolchain can build; all three systems get the same
version.

## restic

```sh
restic init --repo ~/restic-repo
restic -r ~/restic-repo backup ~/Documents
restic -r ~/restic-repo snapshots
restic -r ~/restic-repo restore latest --target ~/restored
```

Backups to a local directory, SFTP, a REST server, S3 and the other
backends work as in the stock restic. Not available: `restic mount` (no FUSE)
and `restic self-update`. Extended attributes are not backed up.

## Hugo

```sh
hugo new site mysite
cd mysite
hugo server                  # then open http://127.0.0.1:1313
hugo                         # build into public/
```

This is the standard edition. The extended edition's Sass compiler and WebP
encoder need cgo, so themes that need "Hugo extended" do not build. Hugo
server picks up edits and rebuilds while it runs.

## Caddy

```sh
caddy file-server --root ~/public_html --listen 127.0.0.1:8080
caddy run --config Caddyfile
caddy reload --config Caddyfile
caddy stop
```

The standard modules (file server, reverse proxy, automatic HTTPS, the
Caddyfile). The admin endpoint listens on `127.0.0.1:2019` instead of
`localhost:2019`. On x86_64 and 32-bit x86 Go programs still cannot look
up `localhost`, as Haiku has no `/etc/hosts`; write `127.0.0.1` rather
than `localhost` there, as in `reverse_proxy 127.0.0.1:3000`. The arm64
build reads Haiku's hosts file, so `localhost` works there.

## fzf

```sh
ls /boot/system/bin | fzf
fzf --filter=term < list.txt   # non-interactive
```

## lazygit

```sh
cd my-repository
lazygit
```

lazygit needs `git` 2.32 or later. On x86_64 and 32-bit x86 Haiku has it
(`pkgman install git`, or `git_x86` on 32-bit x86); the RenkuOS arm64
repository has no git yet, so there lazygit only starts far enough to say so.

## Stopping a running command

Ctrl-C and `kill` stop `syncthing`, `rclone serve`, `hugo server`,
`caddy file-server` and the rest on all three systems. On arm64 this needs
the packages built with the fixed toolchain (see the revisions above):
older arm64 builds ignored both, and only `kill -9` stopped them.

## Uninstall

```sh
pkgman uninstall rclone      # or syncthing, github_cli, restic, hugo, caddy,
                             # fzf, lazygit; add _x86 on 32-bit x86
```

## Building

`build.sh` cross-builds a tool on a workstation and `package.sh` makes the
package. The patches and the Go toolchains they need are described in
[docs/PORTING.md](docs/PORTING.md).

## AI disclosure

Parts of this port were developed with the assistance of AI coding tools
(Anthropic's Claude). All code has been reviewed and tested by the author.
