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
log = Path(os.environ["PDC_TEST_INVOCATIONS"])
attempt = len(log.read_text().splitlines()) if log.exists() else 0
with log.open("a", encoding="utf-8") as calls:
    calls.write("invoke\n")

sequence = os.environ.get("PDC_TEST_RESPONSE", "success").split(",")
case = sequence[min(attempt, len(sequence) - 1)]
private = f"DO-NOT-EMIT {os.environ['EXPECTED_SECRET_ARN']}"
throttle = f"An error occurred (TooManyRequestsException) when calling the Invoke operation (reached max retries: 0): {private}"
if case in ("throttle", "legacy-throttle"):
    print(f"\naws: [ERROR]: {throttle}\n\nAdditional error details:\nmessage: {private}" if case == "throttle" else throttle, file=sys.stderr)
    sys.exit(254)
if case in ("denied", "unknown-format", "unsafe-code"):
    code = {"denied": "AccessDeniedException", "unsafe-code": "Error000000000004"}.get(case)
    print(f"An error occurred ({code}) when calling the Invoke operation: {private}\n{throttle}" if code else private, file=sys.stderr)
    sys.exit(254)
if case in ("transport", "read-timeout"):
    print(f"Read timeout on endpoint URL: {private}" if case == "read-timeout" else throttle, file=sys.stderr)
    sys.exit(255)
Path(args[-1]).write_text("null" if case == "success" else '"DO-NOT-EMIT"', encoding="utf-8")
print(json.dumps({"StatusCode": 200} | ({"FunctionError": "Unhandled"} if case == "function" else {})))
