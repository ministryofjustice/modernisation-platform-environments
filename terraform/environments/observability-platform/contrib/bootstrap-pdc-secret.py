"""Create the first agent token via Lambda. Never emit the response body or store it in Terraform."""

import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time


# Allow one occupied 900-second Lambda slot to clear. Never retry an uncertain execution.
THROTTLE_BACKOFF = (10, 20, 40) + (60,) * 14


def invoke_error_code(result):
    if result.returncode != 254:  # AWS CLI v2 service error
        return None
    match = re.match(
        rb"(?:aws: \[ERROR\]: )?An error occurred \(([A-Za-z][A-Za-z0-9]{0,63})\) "
        rb"when calling the Invoke operation(?: \(reached max retries: 0\))?:",
        result.stderr.lstrip(),
    )
    if match and not re.search(rb"[0-9]{12}", match[1]):
        return match[1].decode("ascii")
    return None


def invoke(function_arn, payload, response):
    for delay in (0, *THROTTLE_BACKOFF):
        if delay:
            print(f"PDC bootstrap Invoke rejected (TooManyRequestsException); retrying in {delay}s.", file=sys.stderr)
            time.sleep(delay)
        result = subprocess.run(
            [
                "aws", "lambda", "invoke", "--function-name", function_arn,
                "--region", function_arn.split(":")[3], "--invocation-type", "RequestResponse",
                "--cli-binary-format", "raw-in-base64-out", "--payload", json.dumps(payload),
                "--cli-read-timeout", "910", "--output", "json", str(response),
            ],
            env=os.environ | {"AWS_MAX_ATTEMPTS": "1", "AWS_PAGER": ""},
            capture_output=True,
            check=False,
        )
        if result.returncode == 0:
            return result.stdout
        code = invoke_error_code(result)
        if code != "TooManyRequestsException":
            diagnostic = code or f"AWS CLI exit {result.returncode}"
            raise SystemExit(f"PDC bootstrap invocation failed ({diagnostic}); inspect the journal before retrying.")
    raise SystemExit("PDC bootstrap Invoke rejected (TooManyRequestsException); retry limit reached.")


def main():
    function_arn = os.environ["PDC_FUNCTION_ARN"]
    payload = {"Step": "bootstrapSecret", "SecretId": os.environ["PDC_SECRET_ARN"]}
    # The AWS CLI writes the function payload separately from invocation metadata.
    with tempfile.TemporaryDirectory() as directory:
        response = Path(directory, "response")
        stdout = invoke(function_arn, payload, response)
        try:
            metadata = json.loads(stdout)
            if not isinstance(metadata, dict) or metadata.get("StatusCode") != 200 or "FunctionError" in metadata:
                raise SystemExit("PDC bootstrap Lambda failed; inspect the journal before retrying.")
            if json.loads(response.read_bytes()) is not None:
                raise SystemExit("Unexpected PDC bootstrap response; inspect the journal before retrying.")
        except (ValueError, FileNotFoundError):
            raise SystemExit("Invalid PDC bootstrap response; inspect the journal before retrying.") from None


if __name__ == "__main__":
    main()
