#!/usr/bin/env bash
# sync-template.sh - Sync shared infra from private instance to public template
#
# Usage:
#   ./scripts/sync-template.sh              Diff, copy, commit, and push
#   ./scripts/sync-template.sh --dry-run    Preview changes without modifying anything
#   ./scripts/sync-template.sh --diff       Show file-level diff only
#
# Syncs the shared infrastructure files (protocols, scripts, docs, config)
# from this private instance to the public hive-mind template repo.
# Private content (knowledge-base, .beads, team models) is never copied.
#
# Requires: hive-mind-main (public template) checked out as a sibling directory.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRIVATE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_DIR="$(cd "$PRIVATE_DIR/.." && pwd)"
PUBLIC_DIR="$WORKSPACE_DIR/hive-mind-main"

DRY_RUN=false
DIFF_ONLY=false

# --- Shared paths manifest ---
# These paths are synced from private → public template.
# Everything else is private and stays out of the public repo.
SHARED_PATHS=(
    "CLAUDE.md"
    "README.md"
    ".gitignore"
    ".claude/settings.json"
    "protocols/"
    "scripts/"
    "docs/"
    ".aur2/AUR2.md"
    ".aur2/.env.example"
    ".aur2/.gitignore"
)

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --diff)
            DIFF_ONLY=true
            shift
            ;;
        -h|--help)
            head -12 "$0" | tail -10
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

# --- Validate ---
if [[ ! -d "$PUBLIC_DIR" ]]; then
    echo "ERROR: Public template not found at $PUBLIC_DIR"
    echo "Clone it with: git clone https://github.com/ocampbell-stack/hive-mind.git $PUBLIC_DIR"
    exit 1
fi

if [[ ! -d "$PUBLIC_DIR/.git" ]]; then
    echo "ERROR: $PUBLIC_DIR is not a git repository"
    exit 1
fi

# --- Build file list ---
# Expand directories into individual files, skip anything that doesn't exist
FILES=()
for path in "${SHARED_PATHS[@]}"; do
    full="$PRIVATE_DIR/$path"
    if [[ -d "$full" ]]; then
        while IFS= read -r file; do
            FILES+=("${file#$PRIVATE_DIR/}")
        done < <(find "$full" -type f ! -name ".DS_Store")
    elif [[ -f "$full" ]]; then
        FILES+=("$path")
    fi
done

# --- Diff ---
CHANGED=()
NEW=()
IDENTICAL=()

for file in "${FILES[@]}"; do
    src="$PRIVATE_DIR/$file"
    dst="$PUBLIC_DIR/$file"

    if [[ ! -f "$dst" ]]; then
        NEW+=("$file")
    elif ! diff -q "$src" "$dst" > /dev/null 2>&1; then
        CHANGED+=("$file")
    else
        IDENTICAL+=("$file")
    fi
done

# --- Report ---
echo "=== Sync: Private → Public Template ==="
echo "Private: $PRIVATE_DIR"
echo "Public:  $PUBLIC_DIR"
echo ""

if [[ ${#CHANGED[@]} -eq 0 && ${#NEW[@]} -eq 0 ]]; then
    echo "Already in sync. Nothing to do."
    exit 0
fi

if [[ ${#CHANGED[@]} -gt 0 ]]; then
    echo "Changed (${#CHANGED[@]}):"
    for f in "${CHANGED[@]}"; do
        echo "  M $f"
    done
    echo ""
fi

if [[ ${#NEW[@]} -gt 0 ]]; then
    echo "New (${#NEW[@]}):"
    for f in "${NEW[@]}"; do
        echo "  A $f"
    done
    echo ""
fi

echo "${#IDENTICAL[@]} files already in sync."
echo ""

if $DIFF_ONLY; then
    exit 0
fi

if $DRY_RUN; then
    echo "=== DRY RUN — no changes made ==="
    exit 0
fi

# --- Copy ---
echo "--- Copying files ---"
for file in "${CHANGED[@]}" "${NEW[@]}"; do
    dst="$PUBLIC_DIR/$file"
    mkdir -p "$(dirname "$dst")"
    cp "$PRIVATE_DIR/$file" "$dst"
    echo "  $file"
done
echo ""

# --- Commit and push ---
echo "--- Committing to public template ---"
cd "$PUBLIC_DIR"
git add -A

# Build a commit message summarizing what changed
SUMMARY=""
if [[ ${#CHANGED[@]} -gt 0 ]]; then
    SUMMARY+="${#CHANGED[@]} updated"
fi
if [[ ${#NEW[@]} -gt 0 ]]; then
    [[ -n "$SUMMARY" ]] && SUMMARY+=", "
    SUMMARY+="${#NEW[@]} new"
fi

git commit -m "$(cat <<EOF
Sync shared infra from private instance ($SUMMARY)

Files synced:
$(for f in "${CHANGED[@]}"; do echo "  M $f"; done)
$(for f in "${NEW[@]}"; do echo "  A $f"; done)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"

echo ""
echo "--- Pushing to origin ---"
git push

echo ""
echo "=== Sync complete ==="
echo "Public template is up to date."
