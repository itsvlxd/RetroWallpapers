#!/usr/bin/env bash
# Rebuilds metadata.json by scanning collection branches.
#
# Local usage:  bash scripts/build_metadata.sh
# GitHub Action: bash scripts/build_metadata.sh --gh
#
# Scans git branches (except main), counts wallpaper files and their total
# size, records the branch HEAD sha, and writes metadata.json.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GH="${1:-}"

REPO_URL="https://github.com/itsvlxd/retrowallpapers.git"
RAW_BASE="https://raw.githubusercontent.com/itsvlxd/retrowallpapers/main"

# In GH Actions we clone with --no-checkout (branches live as local refs).
if [[ $GH == "--gh" ]]; then
    cd "$ROOT"
else
    cd "$ROOT"
    git fetch origin --all --prune 2>/dev/null || true
fi

# Enumerate branches (excluding main). Local: refs/heads/*. GH: refs/remotes/origin/*.
mapfile -t branches < <(git for-each-ref --format='%(refname)' refs/heads refs/remotes/origin 2>/dev/null \
    | sed 's#^refs/heads/##; s#^refs/remotes/origin/##' \
    | grep -vE '^(main|HEAD)$' | sort -u)

COLS=""
FIRST=1
for branch in "${branches[@]}"; do
    [[ -n $branch ]] || continue

    count=0
    size=0
    while IFS=$'\t' read -r sz path; do
        [[ -z $sz ]] && continue
        count=$((count + 1))
        size=$((size + sz))
    done < <(git ls-tree -rl "$branch" 2>/dev/null | awk '{print $4"\t"$5}' | grep -iE '\.(png|jpg|jpeg|webp|gif|mp4|mkv|webm)$')

    [[ $count -eq 0 ]] && continue

    sha=$(git rev-parse "$branch" 2>/dev/null || true)
    [[ -z $sha ]] && continue

    size_mb=$(awk -v b="$size" 'BEGIN{printf "%.1f", b/1048576}')
    desc=""
    case "$branch" in
        noir) desc="Dark, monochrome and cinematic. Stripped of color, full of mood." ;;
        retro) desc="Neon-soaked synthwave, retro cars and outrun vibes." ;;
        sunset) desc="Golden-hour landscapes, calm oceans and warm skies." ;;
    esac

    entry=$(printf '{"name":"%s","branch":"%s","count":%d,"size_bytes":%d,"size_human":"%s MB","sha":"%s","description":"%s"}' \
        "$branch" "$branch" "$count" "$size" "$size_mb" "$sha" "$desc")

    if [[ $FIRST == 1 ]]; then
        COLS="$entry"
        FIRST=0
    else
        COLS="$COLS,$entry"
    fi
done

if [[ -z $COLS ]]; then
    COLS="[]"
else
    COLS="[$COLS]"
fi

cat > "$ROOT/metadata.json" <<EOF
{
  "repo_url": "$REPO_URL",
  "raw_base": "$RAW_BASE",
  "collections": $COLS
}
EOF

echo "metadata.json updated: $COLS"
