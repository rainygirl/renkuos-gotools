# Go tools for RenkuOS

English · [Italiano](README.it.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

rclone, Syncthing and the GitHub CLI, built for RenkuOS (Haiku) on arm64,
x86_64 and 32-bit x86. Unofficial builds, not affiliated with the rclone
project, the Syncthing Foundation or GitHub.

| Tool | Version | Package | Package on 32-bit x86 |
| --- | --- | --- | --- |
| rclone | 1.76.0 | `rclone` | `rclone_x86` |
| Syncthing | 1.30.0 | `syncthing` | `syncthing_x86` |
| GitHub CLI (`gh`) | 2.100.0 | `github_cli` | `github_cli_x86` |

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
`syncthing` or `gh`.

## Install a package file

Without the repository, with a `.hpkg` built by `package.sh`:

```sh
pkgman install ./rclone-1.76.0-1-arm64.hpkg
```

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

## On arm64: stopping a running command

On RenkuOS arm64 a Go program does not react to Ctrl-C or to `kill` yet (the
Go runtime there does not deliver signals), so `syncthing` or
`rclone serve` keep running. Shut Syncthing down from its web page (Actions ->
Shutdown); stop anything else with `kill -9 <team id>` or from
ProcessController. x86_64 and 32-bit x86 are not affected.

## Uninstall

```sh
pkgman uninstall rclone      # or syncthing, github_cli; add _x86 on 32-bit x86
```

## Building

`build.sh` cross-builds a tool on a workstation and `package.sh` makes the
package. The patches and the Go toolchains they need are described in
[docs/PORTING.md](docs/PORTING.md).

## AI disclosure

Parts of this port were developed with the assistance of AI coding tools
(Anthropic's Claude). All code has been reviewed and tested by the author.
