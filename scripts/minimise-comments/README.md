Script for hiding comments in a PR

Set environment variables as follows before running the script

```
COMMENT_BODY_CONTAINS="set this to a string which is in the comment to hide"
PR_NUMBER="set this to the PR number"
GITHUB_REPOSITORY="set to name of repo"
GITHUB_TOKEN="set to github token"
```

Example usage once environment vars are set

```
go build
./minimise-comments
```
