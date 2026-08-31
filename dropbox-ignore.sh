#!/usr/bin/env bash
#
# Keep Dropbox from syncing Quarto's build artifacts.
#
# Why this exists: `quarto render` deletes and recreates docs/, .quarto/ and
# _freeze/. A recreated directory comes back WITHOUT the extended attributes
# that mark it as ignored, so Dropbox silently resumes syncing it and starts
# generating "conflicted copy" files across machines. This re-applies the
# flags on every render.
#
# Wired into _quarto.yml as both a pre-render and post-render step.
# Deliberately never fails: a backup-hygiene script must not break a render.
#
# Dropbox's File Provider engine reads com.apple.fileprovider.ignore#P;
# com.dropbox.ignored is the legacy/secondary attribute. Set both.
# See: https://help.dropbox.com/sync/ignored-files

set -u

# macOS only - these attributes mean nothing elsewhere.
[ "$(uname)" = "Darwin" ] || exit 0
command -v xattr >/dev/null 2>&1 || exit 0

cd "$(dirname "$0")" || exit 0

IGNORE_DIRS=(docs .quarto _freeze)

for d in "${IGNORE_DIRS[@]}"; do
    # Create it if the render hasn't yet, so the flag is in place beforehand.
    [ -e "$d" ] || mkdir -p "$d" 2>/dev/null || continue

    xattr -w 'com.apple.fileprovider.ignore#P' 1 "$d" 2>/dev/null
    xattr -w com.dropbox.ignored 1 "$d" 2>/dev/null
done

exit 0
