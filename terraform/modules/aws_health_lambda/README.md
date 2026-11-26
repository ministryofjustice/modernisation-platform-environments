# AWS Health Lambda Module

## Overview

This module forwards AWS Health events to a GitHub repository as issues,
except for resolved events and configured ignored findings.

Issues are added to the organisation project identified by
`github_project_number`, and its single-select `Source` field is set to
`github_issue_source` (default: `Support`). The configured option must exist.

## Running Tests

Set up local requirements in a virtualenv

```bash
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install boto3 -r lambda/requirements.txt
```

Then run the tests

`python3 -m unittest discover -s lambda -p test_handler.py -v`
