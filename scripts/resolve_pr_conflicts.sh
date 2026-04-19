#!/usr/bin/env bash
set -euo pipefail

# Resolve recurring PR conflicts by preferring this branch's versions
# for known conflict-prone files after merging the latest base branch.

BASE_BRANCH="${1:-origin/main}"

CONFLICT_FILES=(
  "APGI-Explorer/AppDelegate.swift"
  "APGI-Explorer/CrashReportingManager.swift"
  "APGI-Explorer/FileOperationRecoveryManager.swift"
  "APGI-Explorer/FileStorageManager.swift"
  "APGI-Explorer/MenuBarView.swift"
  "APGI-Explorer/ScreenshotAutomationEngine.swift"
  "APGI-Explorer/SettingsView.swift"
  "APGI-Explorer/SettingsViews/CloudSyncSettingsView.swift"
  "APGI-Explorer/SettingsViews/DataPrivacySettingsView.swift"
  "AUDIT_FINDINGS_2026-04-18.md"
  "README.md"
)

echo "[1/4] Fetching latest refs..."
git fetch --all --prune

echo "[2/4] Starting merge from ${BASE_BRANCH}..."
merge_output="$(git merge --no-commit --no-ff "${BASE_BRANCH}" 2>&1 || true)"
echo "${merge_output}"

if [[ "${merge_output}" == *"Already up to date."* ]]; then
  echo "Branch is already up to date with ${BASE_BRANCH}. Nothing to resolve."
  exit 0
fi

if [[ "${merge_output}" == *"CONFLICT"* ]]; then
  echo "Merge reported conflicts. Applying deterministic conflict resolution..."
fi

echo "[3/4] Resolving known conflict files with --ours..."
for f in "${CONFLICT_FILES[@]}"; do
  if git ls-files -u -- "$f" | grep -q .; then
    git checkout --ours -- "$f"
    git add "$f"
    echo "  resolved: $f"
  fi
done

# If any unknown conflicts remain, fail clearly so they are handled explicitly.
if git diff --name-only --diff-filter=U | grep -q .; then
  echo "ERROR: unresolved conflicts remain:"
  git diff --name-only --diff-filter=U
  exit 2
fi

echo "[4/4] Finalizing merge commit..."
if git diff --cached --quiet; then
  echo "No staged merge changes found. Aborting merge state."
  git merge --abort || true
  exit 0
fi

git commit -m "Merge ${BASE_BRANCH} and resolve recurring PR conflicts"
echo "Done."
