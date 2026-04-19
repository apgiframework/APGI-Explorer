# Merge Conflict Playbook (GitHub PR)

If your PR still shows **"This branch has conflicts that must be resolved"**, use one of the two methods below.

## Method A (Recommended): Resolve locally and push

> Use this on your machine (or any runner) that has network access to GitHub.

```bash
# 1) Clone and enter repo
git clone https://github.com/<OWNER>/<REPO>.git
cd <REPO>

# 2) Checkout your PR branch
git fetch origin
git checkout <PR_BRANCH>

# 3) Ensure resolver script is executable
chmod +x scripts/resolve_pr_conflicts.sh

# 4) Run deterministic conflict resolver against the PR target branch
#    (usually main)
./scripts/resolve_pr_conflicts.sh origin/main

# 5) Push the merge-resolution commit to your PR branch
git push origin <PR_BRANCH>
```

## Method B: Run the GitHub Action from UI

> Use this when you don’t want to run local git commands.

1. Open your repository on GitHub.
2. Go to **Actions** → **Resolve PR Conflicts**.
3. Click **Run workflow**.
4. Set:
   - `base_branch`: `main` (or your PR target)
   - `head_branch`: your PR branch name
5. Run the workflow.
6. Refresh the PR page after the workflow finishes.

## Verify conflicts are gone

```bash
# Optional local validation after running Method A
git fetch origin
git checkout <PR_BRANCH>
git merge --no-commit --no-ff origin/main

# If this reports "Already up to date" or exits with no conflicts,
# your PR should be mergeable.

# Clean up no-commit merge state if needed:
git merge --abort || true
```

## Common failure and fix

### Error: `fatal: unable to access ... CONNECT tunnel failed, response 403`

Your environment cannot reach GitHub over HTTPS. Run Method A from a machine/runner with outbound network access, or use Method B from GitHub Actions.

## Notes

- The resolver only auto-resolves the known recurring conflict file set.
- If new files conflict, the script intentionally fails and prints unresolved files so you can resolve them manually.
