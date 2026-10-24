#!/usr/bin/env bash
# Prepare the MAME headless source used by MAME/MAME.xcodeproj.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
MAME_DIR="$REPO_ROOT/MAME"
DEPS_DIR="$MAME_DIR/deps"
SRC_DIR="$DEPS_DIR/mame"
PATCH_FILE="$MAME_DIR/patches/mame-0289-headless.patch"
REVISION="f34f02505e32c1993c6a782b6814232cbfc74e36"
REMOTE="https://github.com/mamedev/mame.git"

mkdir -p "$DEPS_DIR"

if [ ! -e "$SRC_DIR/.git" ]; then
  echo "Cloning mamedev/mame into $SRC_DIR..."
  git clone --depth 1 --branch mame0289 --single-branch "$REMOTE" "$SRC_DIR"
fi

cd "$SRC_DIR"

# Existing checkouts may point at a headless fork; use the official source.
git remote set-url origin "$REMOTE"

if ! git cat-file -e "$REVISION^{commit}" 2>/dev/null; then
  git fetch --depth 1 --no-tags origin "$REVISION"
fi
# Remove only the known compatibility patch when upgrading an old 0.250 checkout.
# Other local edits are retained; checkout/apply will stop on conflicts.
OLD_PATCH="$MAME_DIR/patches/mame-headless-clang21-apple.patch"
if [ "$(git rev-parse HEAD)" = "fac13e827b7b8cfa4ee4f5760198d31241e2a544" ] &&
   git apply --reverse --check "$OLD_PATCH" >/dev/null 2>&1; then
  git apply --reverse "$OLD_PATCH"
fi

git checkout --detach "$REVISION"

if git apply --check "$PATCH_FILE" >/dev/null 2>&1; then
  echo "Applying OpenEmu headless backend patch..."
  git apply "$PATCH_FILE"
elif git apply --reverse --check "$PATCH_FILE" >/dev/null 2>&1; then
  echo "Patch already applied."
else
  echo "error: patch does not apply cleanly and is not already applied: $PATCH_FILE" >&2
  git status --short >&2 || true
  exit 1
fi

echo "MAME source ready at $SRC_DIR"
