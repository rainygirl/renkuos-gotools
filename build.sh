#!/bin/sh
# build.sh - cross-build one tool for RenkuOS/Haiku.
#
#   ./build.sh rclone arm64
#   ./build.sh syncthing x86_64
#   ./build.sh gh x86_gcc2            # 32-bit x86
#
# Clones the tool at the version pinned in tools/<tool>.conf, applies
# patches/<tool>.patch if there is one, swaps in patched copies of the
# dependencies that do not build for Haiku (patches/deps/, versions in
# tools/deps.list), and writes dist/<arch>/<binary>.
#
# Runs on any machine that has a Go toolchain able to target Haiku on that
# architecture. Name it with GO, or per architecture:
#
#   GO_ARM64      github.com/rainygirl/renkuos-golang, golang_bin revision
#                 10 or later (signal and startup fixes); an older tree
#                 needs patches/go/go-haiku-arm64-startup.patch
#   GO_X86_64     github.com/korli/go, branch golang-1.27-haiku
#   GO_X86_GCC2   github.com/rainygirl/renkuos-golang-x86, revision 2 or
#                 later: the cross toolchain its build.sh leaves in
#                 .work/go/bin/go, with the whole haiku/386 patch series
#
# docs/PORTING.md says why. With an older arm64 tree the binaries print
# "234567" at every start and ignore SIGTERM and Ctrl-C; an older 32-bit
# toolchain crashes or misplaces file offsets.
#
# Environment:
#   WORK     scratch directory (default: ./.work)
#   KEEP=1   reuse the checkout in WORK instead of cloning again
set -eu

die() { echo "error: $*" >&2; exit 1; }
note() { echo "==> $*"; }

[ $# -eq 2 ] || die "usage: $0 <tool> arm64|x86_64|x86_gcc2 (one of tools/*.conf)"
tool=$1
case $2 in
	arm64) arch=arm64; goarch=arm64; go=${GO:-${GO_ARM64:-go}} ;;
	x86_64|amd64) arch=x86_64; goarch=amd64; go=${GO:-${GO_X86_64:-go}} ;;
	x86_gcc2|x86|i386|386) arch=x86_gcc2; goarch=386; go=${GO:-${GO_X86_GCC2:-go}} ;;
	*) die "unknown architecture: $2 (arm64, x86_64 or x86_gcc2)" ;;
esac

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
[ -f "$here/tools/$tool.conf" ] || die "unknown tool: $tool"
work=${WORK:-$here/.work}
src=$work/src/$tool
deps=$work/deps
out=$here/dist/$arch

command -v "$go" >/dev/null 2>&1 || die "no Go toolchain: set GO=/path/to/go"
# Before the first "$go" command, so the checks below cannot download
# another toolchain on behalf of a go.mod or GOTOOLCHAIN in the environment.
export GOTOOLCHAIN=local
"$go" tool dist list 2>/dev/null | grep -qx "haiku/$goarch" \
	|| die "$("$go" version) cannot target haiku/$goarch; see the header of this script"
# patches/deps/sys.patch's 386 mmap relies on the zero-padded argument window
# of go-haiku386-syscallargs.patch (renkuos-golang-x86 revision 2).
[ "$goarch" != 386 ] \
	|| grep -q 'args := \[8\]uintptr' "$("$go" env GOROOT)/src/runtime/syscall_haiku.go" 2>/dev/null \
	|| die "$("$go" env GOROOT) is not a renkuos-golang-x86 (revision 2+) tree; see the header of this script"

. "$here/tools/$tool.conf"

mkdir -p "$work" "$out" "$deps"
export GOFLAGS=-mod=mod
export GOPATH=${GOPATH:-$work/gopath}
export GOCACHE=${GOCACHE:-$work/gocache-$arch}

# --- source ------------------------------------------------------------------

if [ -d "$src/.git" ] && [ "${KEEP:-0}" = 1 ]; then
	note "reusing $src"
else
	rm -rf "$src"
	note "cloning $tool $TAG"
	git clone --quiet --depth 1 --branch "$TAG" "$REPO" "$src" 2>/dev/null \
		|| die "cannot clone $REPO at $TAG"
	if [ -f "$here/patches/$tool.patch" ]; then
		git -C "$src" apply --check "$here/patches/$tool.patch" \
			|| die "patches/$tool.patch does not apply to $TAG"
		git -C "$src" apply "$here/patches/$tool.patch"
		note "applied patches/$tool.patch"
	fi
fi

# --- patched dependencies ----------------------------------------------------

# Each one is the pinned version copied out of the module cache, patched, and
# pulled in with a replace directive. The cache itself stays pristine. A tool
# gets the pinned version even where its go.mod asks for another: one patch
# per module rather than one per version.
for name in $DEPS; do
	line=$(grep "^$name " "$here/tools/deps.list") || die "tools/deps.list has no $name"
	module=$(echo "$line" | cut -d' ' -f2)
	version=$(echo "$line" | cut -d' ' -f3)
	if [ ! -f "$deps/$name/.patched" ]; then
		dir=$(cd "$work" && "$go" mod download -json "$module@$version" \
			| sed -n 's/^[[:space:]]*"Dir": "\(.*\)",\{0,1\}$/\1/p')
		[ -d "$dir" ] || die "cannot download $module@$version"
		rm -rf "$deps/$name"
		cp -R "$dir" "$deps/$name"
		chmod -R u+w "$deps/$name"
		patch -s -d "$deps/$name" -p1 < "$here/patches/deps/$name.patch"
		: > "$deps/$name/.patched"
		note "patched $module $version"
	fi
	(cd "$src" && "$go" mod edit -replace "$module=$deps/$name")
done

# --- build -------------------------------------------------------------------

prebuild
note "building $tool $VERSION for haiku/$goarch with $("$go" version)"
(
	cd "$src"
	CGO_ENABLED=0 GOOS=haiku GOARCH=$goarch "$go" build -trimpath \
		-tags="$BUILD_TAGS" -ldflags="-s -w $(ldflags)" \
		-o "$out/$BIN" "$MAIN"
)
cp "$src/$UPSTREAM_LICENSE" "$out/$BIN.LICENSE"
if command -v file >/dev/null 2>&1; then
	file "$out/$BIN"
fi
note "built $out/$BIN"
