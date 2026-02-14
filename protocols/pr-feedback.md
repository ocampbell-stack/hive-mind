# PR Feedback Protocol

This protocol governs how agents address review feedback on pull requests. Use it when asked to iterate on an existing PR (e.g., via `/hive.iterate`).

## Steps

### 1. Identify the PR

- If a PR number or URL was provided, use it directly
- If no input, detect from current branch:
  ```bash
  gh pr list --head $(git branch --show-current) --json number,url
  ```

### 2. Ensure Correct Branch

```bash
git branch --show-current
```
If not on the expected feature branch, check it out:
```bash
git checkout feat/{agent-name}/{description}
```

### 3. Read Review Feedback

```bash
gh pr view <number> --comments
gh api repos/{owner}/{repo}/pulls/<number>/reviews
```

Identify which comments are unresolved or request changes.

### 4. Address Each Comment

For each unresolved review comment:
1. Read the referenced file(s) and understand the requested change
2. Make the change
3. If the change affects KB content, update `knowledge-base/INDEX.md`
4. Re-run verification checks (fidelity, coherence, privacy, professionalism)

### 5. Commit and Push

```bash
git add -A
git commit -m "address review: <summary of changes>"
git push
```

### 6. Notify Reviewer

```bash
gh pr comment <number> --body "Addressed feedback: <bullet list of changes made>"
```

### 7. Update Beads

Find the associated bead (search for one with the PR URL in comments) and add a note:
```bash
bd comments add <id> "Review feedback addressed (round N)"
```

### 8. Report

Summarize to the user:
- What changes were made
- Any comments that could not be addressed and why (need clarification, out of scope, etc.)
