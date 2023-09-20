import base64
import hashlib
import requests
import json
import boto3
import time

file_path = "test_data.csv"
database = "test_product5"
table = "testing"
glue = boto3.client("glue")


def md5_hash_file_contents(file) -> str:
    """This holds the file in memory to hash so
    will be unsuitable for large files"""
    with open(file, "r") as tempfile:
        body = tempfile.read()
    md = hashlib.md5(body.encode("utf-8")).digest()
    contents_md5 = base64.b64encode(md).decode("utf-8")

    return contents_md5


file_md5_hash = md5_hash_file_contents(file_path)

# Get presigned url
response = requests.get(
    url="https://hsolkci589.execute-api.eu-west-2.amazonaws.com/development/upload_data",
    params={"database": database, "table": table, "contentMD5": file_md5_hash},
    headers={"authorizationToken": "placeholder"},
)
response_json = json.loads(response.text)
post_policy_form_data = response_json["URL"]["fields"]
multipart_form_data = {
    **post_policy_form_data,
    "file": (post_policy_form_data["key"], open(file_path, "r")),
}

# Remove any existing table
try:
    glue.get_table(DatabaseName=database, Name=table)
    print(f"{database}.{table} found in glue")
except Exception as e:
    raise e
try:
    glue.delete_table(DatabaseName=database, Name=table)
    print(f"{database}.{table} deleted from glue")
except Exception as e:
    raise e

# Upload data
time.sleep(5)
print("Uploading data")
upload_response = requests.post(response_json["URL"]["url"], files=multipart_form_data)
print(upload_response.status_code, upload_response.text)

print(f"Waiting for {database}.{table} to recreate in athena")
time.sleep(10)

try:
    glue.get_table(DatabaseName=database, Name=table)
    print(f"{database}.{table} recreated in glue")
except Exception as e:
    raise e
