#!/usr/bin/env bash
# Git-specific common functions for the git extension.
# Extracted from scripts/bash/common.sh — contains only git-specific
# branch validation and detection logic.

# Check if we have git available at the repo root
has_git() {
    local repo_root="${1:-$(pwd)}"
    { [ -d "$repo_root/.git" ] || [ -f "$repo_root/.git" ]; } && \
        command -v git >/dev/null 2>&1 && \
        git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

# Strip a single optional path segment (e.g. gitflow "feat/004-name" -> "004-name").
# Only when the full name is exactly two slash-free segments; otherwise returns the raw name.
spec_kit_effective_branch_name() {
    local raw="$1"
    if [[ "$raw" =~ ^([^/]+)/([^/]+)$ ]]; then
        printf '%s\n' "${BASH_REMATCH[2]}"
    else
        printf '%s\n' "$raw"
    fi
}

# Validate that a branch name matches the expected feature branch pattern.
# Accepts sequential (NNNN-*) or timestamp (YYYYMMDD-HHMMSS-*) formats.
# Logic aligned with scripts/bash/common.sh check_feature_branch after effective-name normalization.
check_feature_branch() {
    local raw="$1"
    local has_git_repo="$2"

    # For non-git repos, we can't enforce branch naming but still provide output
    if [[ "$has_git_repo" != "true" ]]; then
        echo "[specify] Warning: Git repository not detected; skipped branch validation" >&2
        return 0
    fi

    local branch
    branch=$(spec_kit_effective_branch_name "$raw")

    local is_valid=false
    # Sequential prefix: four digits, matching specs/NNNN-slug/ in this repo.
    if [[ "$branch" =~ ^[0-9]{4}- ]]; then
        is_valid=true
    fi
    # Timestamp prefix (YYYYMMDD-HHMMSS-), for work that is not getting a number.
    if [[ "$is_valid" != "true" ]] && [[ "$branch" =~ ^[0-9]{8}-[0-9]{6}- ]]; then
        is_valid=true
    fi
    if [[ "$is_valid" != "true" ]]; then
        echo "ERROR: Not on a feature branch. Current branch: $raw" >&2
        echo "Feature branches should be named like: 0025-feature-name or 20260319-143022-feature-name" >&2
        return 1
    fi

    return 0
}
