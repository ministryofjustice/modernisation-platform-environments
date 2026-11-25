#!/usr/bin/env python3
"""Stand in for the AWS CLI: reject anything other than the bootstrap contract."""

import json
import os
from pathlib import Path
import sys


args = sys.argv[1:]
assert args[:2] == ["lambda", "invoke"]
assert args[args.index("--invocation-type") + 1] == "RequestResponse"
assert args[args.index("--function-name") + 1] == os.environ["EXPECTED_FUNCTION_ARN"]
assert args[args.index("--region") + 1] == "eu-west-2"
assert json.loads(args[args.index("--payload") + 1]) == {
    "Step": "bootstrapSecret",
    "SecretId": os.environ["EXPECTED_SECRET_ARN"],
}
assert os.environ["AWS_MAX_ATTEMPTS"] == "1"
with Path(os.environ["PDC_TEST_INVOCATIONS"]).open("a", encoding="utf-8") as calls:
    calls.write("invoke\n")

case = os.environ.get("PDC_TEST_RESPONSE", "success")
if case == "transport":
    sys.exit(1)
Path(args[-1]).write_text("null" if case == "success" else '"DO-NOT-EMIT"', encoding="utf-8")
print(json.dumps({"StatusCode": 200} | ({"FunctionError": "Unhandled"} if case == "function" else {})))
