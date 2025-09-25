# Testing Release Notes Configuration

This document explains how to test the automatic release notes generation setup.

## Prerequisites

- You have push access to the repository
- You have the necessary permissions to create releases

## Testing Steps

### 1. Create a Test Branch

```bash
git checkout -b test-release-notes
```

### 2. Make Some Test Changes

Create a few test commits with different types of changes:

```bash
# Feature commit
git commit -m "feat: add new search predicate for date ranges" -m "Adds support for searching date ranges with start and end dates"

# Bug fix commit  
git commit -m "fix: resolve issue with null value handling in PostgreSQL" -m "Fixes crash when searching with null values in PostgreSQL adapter"

# Documentation commit
git commit -m "docs: update README with new examples" -m "Adds examples for the new date range predicate"

# Internal/refactor commit
git commit -m "refactor: improve error handling in search builder" -m "Internal refactoring to improve error handling"
```

### 3. Create and Push a Test Tag

```bash
# Create a test tag
git tag v4.4.0-test

# Push the tag (this will trigger the release workflow)
git push origin v4.4.0-test
```

### 4. Check the Results

1. Go to the GitHub repository
2. Navigate to "Releases" 
3. Look for the automatically created release with tag `v4.4.0-test`
4. Verify that:
   - The release was created automatically
   - Release notes were generated
   - Changes are categorized correctly
   - Internal/refactor commits are excluded or placed in appropriate categories

### 5. Clean Up

After testing, clean up the test tag and branch:

```bash
# Delete the test tag locally and remotely
git tag -d v4.4.0-test
git push origin --delete v4.4.0-test

# Delete the test branch
git checkout main
git branch -D test-release-notes
```

## Expected Behavior

The automatic release notes should:

- ✅ Create a release automatically when a tag is pushed
- ✅ Generate release notes from commits since the last tag
- ✅ Categorize changes appropriately (Features, Bug Fixes, etc.)
- ✅ Exclude or properly categorize internal/maintenance commits
- ✅ Include links to full changelog and documentation
- ✅ Have a professional, consistent format

## Troubleshooting

If the workflow doesn't trigger:

1. Check that the tag follows the pattern `v*` (starts with 'v')
2. Verify the workflow file is in `.github/workflows/release.yml`
3. Check the Actions tab for any workflow failures
4. Ensure you have the necessary permissions

If release notes aren't generated correctly:

1. Check the `.github/release.yml` configuration
2. Verify that commits have appropriate labels or follow conventional commit format
3. Review the workflow logs in the Actions tab
