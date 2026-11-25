"""Create the first agent token via Lambda. Never emit the response body or store it in Terraform."""

import json
import os
from pathlib import Path
import subprocess
import tempfile


def main():
    function_arn = os.environ["PDC_FUNCTION_ARN"]
    payload = {"Step": "bootstrapSecret", "SecretId": os.environ["PDC_SECRET_ARN"]}
    # The AWS CLI writes the function payload separately from invocation metadata.
    with tempfile.TemporaryDirectory() as directory:
        response = Path(directory, "response")
        result = subprocess.run(
            [
                "aws", "lambda", "invoke", "--function-name", function_arn,
                "--region", function_arn.split(":")[3], "--invocation-type", "RequestResponse",
                "--cli-binary-format", "raw-in-base64-out", "--payload", json.dumps(payload),
                "--cli-read-timeout", "910", "--output", "json", str(response),
            ],
            env=os.environ | {"AWS_MAX_ATTEMPTS": "1", "AWS_PAGER": ""},
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        if result.returncode:
            raise SystemExit(f"PDC bootstrap invocation failed (AWS CLI exit {result.returncode}); inspect the journal before retrying.")
        try:
            metadata = json.loads(result.stdout)
            if not isinstance(metadata, dict) or metadata.get("StatusCode") != 200 or "FunctionError" in metadata:
                raise SystemExit("PDC bootstrap Lambda failed; inspect the journal before retrying.")
            if json.loads(response.read_bytes()) is not None:
                raise SystemExit("Unexpected PDC bootstrap response; inspect the journal before retrying.")
        except (ValueError, FileNotFoundError):
            raise SystemExit("Invalid PDC bootstrap response; inspect the journal before retrying.") from None


if __name__ == "__main__":
    main()
