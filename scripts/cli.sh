#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

export RETRO_DIR="$REPO_ROOT"

source "$REPO_ROOT/lib/colors.sh"
source "$REPO_ROOT/lib/log.sh"
source "$REPO_ROOT/lib/help.sh"

REPO_URL="${WALLPAPER_REPO_URL:-https://github.com/itsvlxd/retrowallpapers.git}"
RAW_BASE="${WALLPAPER_RAW_BASE:-https://raw.githubusercontent.com/itsvlxd/retrowallpapers/main}"
METADATA_FILE="$REPO_ROOT/metadata.json"
README_FILE="$REPO_ROOT/README.md"

_cli_help() {
    rx_help_usage "./cli.sh <command> [options]"
    rx_help_commands "Available commands"
    rx_help_cmd "build" "Compute metadata.json + refresh the README collection table"
    rx_help_cmd "create <name> [dir]" "Create a new collection from a folder of wallpapers"
    rx_help_cmd "publish [--yes]" "Push all collection branches + main to GitHub"
    rx_help_cmd "list" "List collections in this repo"
    rx_help_cmd "--help, -h" "Show this help message"
    rx_help_examples
    rx_help_example "./cli.sh build" "Regenerate metadata + README"
    rx_help_example "./cli.sh create neon /tmp/my-wallpapers" "Create the 'neon' collection"
    rx_help_example "./cli.sh publish --yes" "Push everything, skip prompts"
    rx_help_spacer
}

_is_valid_collection() {
    [[ $1 =~ ^[a-z0-9_-]+$ ]]
}

# Enumerate collection branches (all refs, excluding main).
_collection_branches() {
    git -C "$REPO_ROOT" for-each-ref --format='%(refname)' refs/heads refs/remotes/origin 2>/dev/null \
        | sed 's#^refs/heads/##; s#^refs/remotes/origin/##' \
        | grep -vE '^(main|HEAD)$' | sort -u
}

# Compute metadata for a single branch and emit a JSON entry.
_branch_meta() {
    local branch="$1"
    local count=0 size=0

    while IFS=$'\t' read -r sz path; do
        [[ -z $sz ]] && continue
        count=$((count + 1))
        size=$((size + sz))
    done < <(git -C "$REPO_ROOT" ls-tree -rl "$branch" 2>/dev/null | awk '{print $4"\t"$5}' | grep -iE '\.(png|jpg|jpeg|webp|gif|mp4|mkv|webm)$')

    [[ $count -eq 0 ]] && return 1

    local sha size_mb
    sha=$(git -C "$REPO_ROOT" rev-parse "$branch" 2>/dev/null || true)
    [[ -z $sha ]] && return 1
    size_mb=$(awk -v b="$size" 'BEGIN{printf "%.1f", b/1048576}')

    local desc=""
    case "$branch" in
        noir) desc="Dark, monochrome and cinematic. Stripped of color, full of mood." ;;
        retro) desc="Neon-soaked synthwave, retro cars and outrun vibes." ;;
        sunset) desc="Golden-hour landscapes, calm oceans and warm skies." ;;
    esac

    printf '{"name":"%s","branch":"%s","count":%d,"size_bytes":%d,"size_human":"%s MB","sha":"%s","description":"%s"}' \
        "$branch" "$branch" "$count" "$size" "$size_mb" "$sha" "$desc"
}

cmd_build() {
    rx_log "info" "Scanning collection branches..."

    local cols=""
    local first=1
    local branch
    while IFS= read -r branch; do
        [[ -n $branch ]] || continue
        local entry
        if entry=$(_branch_meta "$branch"); then
            if [[ $first == 1 ]]; then
                cols="$entry"
                first=0
            else
                cols="$cols,$entry"
            fi
        fi
    done < <(_collection_branches)

    [[ -z $cols ]] && cols="[]" || cols="[$cols]"

    cat >"$METADATA_FILE" <<EOF
{
  "repo_url": "$REPO_URL",
  "raw_base": "$RAW_BASE",
  "collections": $cols
}
EOF

    rx_log "success" "metadata.json written ($(echo "$cols" | jq 'length' 2>/dev/null || echo 0) collections)"

    cmd_readme
}

cmd_readme() {
    rx_log "info" "Refreshing README collection table..."

    local table=""
    while IFS= read -r line; do
        [[ -z $line ]] && continue
        local name count size desc
        name=$(echo "$line" | jq -r '.name')
        count=$(echo "$line" | jq -r '.count')
        size=$(echo "$line" | jq -r '.size_human')
        desc=$(echo "$line" | jq -r '.description')
        table+="| **$name** | \`$name\` | $count | $size | $desc |"$'\n'
    done < <(jq -c '.collections[]' "$METADATA_FILE")

    # Replace the rows between COLLECTIONS:START and COLLECTIONS:END with the
    # freshly computed table rows (the header stays in the README).
    awk -v repl="$table" '
        /<!-- COLLECTIONS:START -->/ { print; in_table=1; printf "%s", repl; next }
        /<!-- COLLECTIONS:END -->/   { print; in_table=0; next }
        !in_table                     { print }
    ' "$README_FILE" >"$README_FILE.tmp" && mv "$README_FILE.tmp" "$README_FILE"

    rx_log "success" "README collection table updated"
}

cmd_create() {
    local name="${1:-}"
    local src_dir="${2:-}"

    if [[ -z $name ]]; then
        rx_log "error" "Usage: ./cli.sh create <name> [wallpapers-dir]"
        return 1
    fi
    if ! _is_valid_collection "$name"; then
        rx_log "error" "Invalid collection name: $name (use a-z, 0-9, -, _)"
        return 1
    fi

    if [[ -z $src_dir ]]; then
        rx_log "info" "No source dir given, scanning ./$name"
        src_dir="$REPO_ROOT/$name"
    fi
    if [[ ! -d $src_dir ]]; then
        rx_log "error" "Source directory not found: $src_dir"
        return 1
    fi

    local files
    files=$(find "$src_dir" -maxdepth 1 -type f | grep -icE '\.(png|jpg|jpeg|webp|gif|mp4|mkv|webm)$' || true)
    if [[ $files -eq 0 ]]; then
        rx_log "error" "No wallpaper files found in $src_dir"
        return 1
    fi
    rx_log "info" "Found ${files} wallpaper file(s) in $src_dir"

    if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$name"; then
        rx_log "warn" "Branch '$name' already exists — updating it in place"
        git -C "$REPO_ROOT" checkout "$name" >/dev/null 2>&1
        git -C "$REPO_ROOT" rm -rf . >/dev/null 2>&1 || true
    else
        rx_log "info" "Creating orphan branch '$name'"
        git -C "$REPO_ROOT" checkout --orphan "$name" >/dev/null 2>&1
        git -C "$REPO_ROOT" rm -rf . >/dev/null 2>&1 || true
    fi

    # Clean any leftover files that git rm didn't catch (untracked).
    git -C "$REPO_ROOT" clean -fdx >/dev/null 2>&1 || true

    cp "$src_dir"/* .
    git -C "$REPO_ROOT" add -A
    git -C "$REPO_ROOT" commit -m "feat: $name collection" >/dev/null 2>&1 || {
        rx_log "error" "Nothing to commit (no changes in $name)"
        return 1
    }

    rx_log "success" "Collection '$name' created on branch '$name'"

    git -C "$REPO_ROOT" checkout main >/dev/null 2>&1
    cmd_build
}

cmd_publish() {
    local skip="${1:-false}"

    local origin
    origin=$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null || echo "")
    if [[ -z $origin ]]; then
        rx_log "error" "No git remote 'origin' configured. Add it first:"
        rx_log "info" "  git remote add origin $REPO_URL"
        return 1
    fi

    if [[ $skip != "--yes" ]] && ! rx_confirm "Push all branches + main to $origin?" "N"; then
        rx_log "info" "Publish cancelled"
        return 0
    fi

    rx_log "info" "Pushing main..."
    git -C "$REPO_ROOT" push origin main 2>/dev/null || true

    local branch
    while IFS= read -r branch; do
        [[ -n $branch ]] || continue
        rx_log "info" "Pushing $branch..."
        git -C "$REPO_ROOT" push origin "$branch" 2>/dev/null || true
    done < <(_collection_branches)

    rx_log "success" "All branches pushed. GitHub Action will recompute metadata automatically."
}

cmd_list() {
    rx_log "info" "Collections in this repo:"
    rx_table_header "󰘓" "Collection"

    local branch
    while IFS= read -r branch; do
        [[ -n $branch ]] || continue
        local count
        count=$(git -C "$REPO_ROOT" ls-tree -r --name-only "$branch" 2>/dev/null | grep -icE '\.(png|jpg|jpeg|webp|gif|mp4|mkv|webm)$' || true)
        rx_table_row "󰇄" "$branch" "$count wallpapers" "$PINK" "30"
    done < <(_collection_branches)

    rx_table_separator
    rx_table_spacer
}

_cli_main() {
    local command="${1:-}"
    [[ -z $command ]] && command="help"

    case "$command" in
        build) cmd_build ;;
        readme) cmd_readme ;;
        create) cmd_create "$2" "$3" ;;
        publish) cmd_publish "${2:-}" ;;
        list) cmd_list ;;
        help | -h | --help) _cli_help ;;
        *) _cli_help ;;
    esac
}

if [[ ${BASH_SOURCE[0]} != "${0}" ]]; then
    export -f _cli_main cmd_build cmd_readme cmd_create cmd_publish cmd_list
else
    _cli_main "$@"
fi
