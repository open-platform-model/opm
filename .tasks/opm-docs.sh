#!/usr/bin/env bash
set -euo pipefail

# opm-docs.sh — install the pinned opm-docs release, and keep its two pins equal.
#
# The docs bundle of this catalog (docs-kit.cue) is built by opm-docs, docs-kit's
# tool. Its version is pinned in the repo-root .opm-docs-version (one line, a
# docs-kit release tag such as v0.1.0), which docs-kit's publish.yml also reads
# in CI (docs-kit docs/contracts.md C5, C12). The local tool is that release's
# binary, checksum-verified, never built from source.
#
# Usage (run from the repo root):
#   bash .tasks/opm-docs.sh install     # install or reuse .bin/opm-docs
#   bash .tasks/opm-docs.sh pin-check   # refuse a publish.yml ref that names another release
#
# install downloads opm-docs_<version>_<os>_<arch>.tar.gz and checksums.txt from
# the docs-kit release, checks the archive with sha256sum (refusing an archive
# checksums.txt has no line for; shasum -a 256 where sha256sum is missing, as
# on macOS), and extracts only opm-docs into .bin/
# (gitignored). An installed binary whose `opm-docs version` already names the
# pinned version is reused. A failed check stops here; nothing falls back to
# `go run` or `go install`.
#
# pin-check refuses unless every
# open-platform-model/docs-kit/.github/workflows/publish.yml ref under
# .github/workflows/ names the tag in .opm-docs-version. A workflow `uses:` ref
# cannot be read from a file, so the release is pinned twice; a bump moves both
# in one PR.

PIN_FILE=.opm-docs-version
BIN_DIR=.bin
WORKFLOW_REF=open-platform-model/docs-kit/.github/workflows/publish.yml@

read_pin() {
	if [ ! -f "$PIN_FILE" ]; then
		echo "opm-docs: no $PIN_FILE at the repository root: write the docs-kit release tag (v0.1.0) on one line" >&2
		exit 1
	fi
	local tag
	tag=$(cat "$PIN_FILE")
	if [ "$(wc -l <"$PIN_FILE")" -gt 1 ] || ! printf '%s\n' "$tag" | grep -Eqx 'v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?'; then
		echo "opm-docs: $PIN_FILE must hold one docs-kit release tag such as v0.1.0, not \"$tag\"" >&2
		exit 1
	fi
	printf '%s\n' "$tag"
}

install_opm_docs() {
	local tag version os arch archive base
	tag=$(read_pin)
	version=${tag#v}

	if [ -x "$BIN_DIR/opm-docs" ] && [ "$("$BIN_DIR/opm-docs" version 2>/dev/null || true)" = "opm-docs $version" ]; then
		return 0
	fi

	case "$(uname -s)" in
	Linux) os=linux ;;
	Darwin) os=darwin ;;
	*)
		echo "opm-docs: no release archive for OS $(uname -s); docs-kit ships linux and darwin" >&2
		exit 1
		;;
	esac
	case "$(uname -m)" in
	x86_64 | amd64) arch=amd64 ;;
	aarch64 | arm64) arch=arm64 ;;
	*)
		echo "opm-docs: no release archive for architecture $(uname -m); docs-kit ships amd64 and arm64" >&2
		exit 1
		;;
	esac

	archive="opm-docs_${version}_${os}_${arch}.tar.gz"
	base="https://github.com/open-platform-model/docs-kit/releases/download/${tag}"
	# Global, not local: the EXIT trap runs after this function has returned.
	tmp=$(mktemp -d)
	trap 'rm -rf "$tmp"' EXIT

	echo "opm-docs: installing $tag ($os/$arch) into $BIN_DIR/"
	download "$base/$archive" "$tmp/$archive" "$tag"
	download "$base/checksums.txt" "$tmp/checksums.txt" "$tag"
	if ! grep -q " ${archive}\$" "$tmp/checksums.txt"; then
		echo "opm-docs: checksums.txt of $tag has no line for $archive" >&2
		exit 1
	fi
	(cd "$tmp" && grep " ${archive}\$" checksums.txt | sha256_check)
	tar -xzf "$tmp/$archive" -C "$tmp" opm-docs
	mkdir -p "$BIN_DIR"
	install -m 0755 "$tmp/opm-docs" "$BIN_DIR/opm-docs"
}

# download URL FILE TAG: fetch one release asset, naming the pin on failure.
download() {
	if ! curl -fsSL --retry 3 -o "$2" "$1"; then
		echo "opm-docs: could not download $1 for $3, the release $PIN_FILE pins: check that the docs-kit release exists and carries this asset" >&2
		exit 1
	fi
}

# sha256_check: `sha256sum -c -`, or `shasum -a 256 -c -` where sha256sum is
# missing (macOS).
sha256_check() {
	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum -c -
	else
		shasum -a 256 -c -
	fi
}

pin_check() {
	local tag refs bad
	tag=$(read_pin)
	refs=$(grep -rhoE "${WORKFLOW_REF}[^[:space:]\"']*" .github/workflows/ || true)
	if [ -z "$refs" ]; then
		echo "opm-docs: no ${WORKFLOW_REF}<tag> reference under .github/workflows/" >&2
		exit 1
	fi
	bad=$(printf '%s\n' "$refs" | grep -vxF "${WORKFLOW_REF}${tag}" || true)
	if [ -n "$bad" ]; then
		echo "opm-docs: $PIN_FILE pins $tag, but these workflow refs name another release; move both in one PR:" >&2
		printf '%s\n' "$bad" | sort -u >&2
		exit 1
	fi
	echo "OK: every docs-kit publish.yml ref names $tag."
}

case "${1:-}" in
install) install_opm_docs ;;
pin-check) pin_check ;;
*)
	echo "Usage: bash .tasks/opm-docs.sh install|pin-check" >&2
	exit 1
	;;
esac
