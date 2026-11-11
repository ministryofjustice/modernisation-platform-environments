# AWS Security Hub Lambda Module

## Overview

This module forwards AWS Security Hub findings with configured severity labels
(default: `CRITICAL`) to a GitHub repository as issues. Each matching finding
creates one issue. Findings from configured source accounts are accepted through
EventBridge, and ignored finding descriptions can be configured through SSM.

## Running Tests

Set up local requirements in a virtualenv

```bash
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install boto3 -r lambda/requirements.txt
```

Then run the tests

`python3 -m unittest discover -s lambda -p test_handler.py -v`
