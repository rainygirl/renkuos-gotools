#!/bin/sh
# package.sh - turn dist/<arch>/<binary> into an installable package.
#
#   ./package.sh rclone arm64         # arm64 | x86_64 | x86_gcc2
#
# Needs Haiku's "package" command: run it on RenkuOS/Haiku, or point PACKAGE
# at a copy built for the workstation (a Haiku build tree makes one with
# "jam -q '<build>package'"; it wants its lib directory in LD_LIBRARY_PATH).
# These packages hold a binary and its licence, nothing with file attributes,
# so either works.
#
# Writes dist/<name>-<version>-<revision>-<arch>.hpkg. On 32-bit x86 the
# package is <name>_x86, as the other RenkuOS packages there are.
#
#   REVISION   package revision (default 1)
#   PACKAGER   packager field (default "rainygirl")
#   VENDOR     vendor field; it has to be the vendor of the repository the
#              package goes into (default "RENKU" for arm64, else "rainygirl")
set -eu

die() { echo "error: $*" >&2; exit 1; }

[ $# -eq 2 ] || die "usage: $0 <tool> arm64|x86_64|x86_gcc2 (one of tools/*.conf)"
tool=$1
arch=$2
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
[ -f "$here/tools/$tool.conf" ] || die "unknown tool: $tool"
src=
go=
. "$here/tools/$tool.conf"

package=${PACKAGE:-package}
command -v "$package" >/dev/null 2>&1 || die "no package command: set PACKAGE (see the header of this script)"
REVISION=${REVISION:-1}
name=$PKG
requires=haiku
case $arch in
	arm64) vendor=${VENDOR:-RENKU} ;;
	x86_64) vendor=${VENDOR:-rainygirl} ;;
	x86_gcc2)
		vendor=${VENDOR:-rainygirl}
		name=${PKG}_x86
		requires="haiku
	haiku_x86"
		;;
	*) die "unknown architecture $arch: arm64, x86_64 or x86_gcc2" ;;
esac
dist=$here/dist/$arch
[ -f "$dist/$BIN" ] || die "missing $dist/$BIN: run ./build.sh $tool $arch"

stage=$here/dist/.stage-$tool-$arch
rm -rf "$stage"
mkdir -p "$stage/bin" "$stage/documentation/packages/$name"
install -m 0755 "$dist/$BIN" "$stage/bin/$BIN"
cp "$dist/$BIN.LICENSE" "$stage/documentation/packages/$name/LICENSE"
cp "$here"/README*.md "$stage/documentation/packages/$name/"

cat > "$stage/.PackageInfo" <<INFO
name		$name
version		$VERSION-$REVISION
architecture	$arch
summary		"$SUMMARY"
description	"$DESCRIPTION"
packager	"${PACKAGER:-rainygirl}"
vendor		"$vendor"
copyrights {
	"$COPYRIGHTS"
}
licenses {
	"$LICENSES"
}
urls {
	"$HOMEPAGE"
}
provides {
	$name = $VERSION
	cmd:$BIN = $VERSION
}
requires {
	$requires
}
INFO

out=$here/dist/$name-$VERSION-$REVISION-$arch.hpkg
rm -f "$out"
(cd "$stage" && "$package" create -q "$out")
rm -rf "$stage"
"$package" list "$out"
echo "==> $out"
