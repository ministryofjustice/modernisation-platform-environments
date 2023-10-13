import base64
import hashlib
import sys
import time

import boto3
import requests


filename = "test_data.csv"
data_product_name = "example_prison_data_product"
table_name = "testing"
base_url = "https://hsolkci589.execute-api.eu-west-2.amazonaws.com/development"
presigned_url = f"/data-product/{data_product_name}/table/{table_name}/upload"
url = base_url + presigned_url
glue = boto3.client("glue")


def md5_hash_file_contents(file) -> str:
    """This holds the file in memory to hash so
    will be unsuitable for large files"""
    with open(file, "r") as tempfile:
        body = tempfile.read()
    md = hashlib.md5(body.encode("utf-8")).digest()
    contents_md5 = base64.b64encode(md).decode("utf-8")

    return contents_md5


file_md5_hash = md5_hash_file_contents(filename)

body = {
    "filename": filename,
    "contentMD5": file_md5_hash,
}

headers = {"authorizationToken": "placeholder"}

# Get presigned url
response = requests.post(
    url=url,
    json=body,
    headers=headers,
)

if response.status_code != 200:
    print(f"Error getting presigned url. Status code: {response.status_code}")
    print(f"Error getting presigned url. Response: {response.text}")
    print("Exiting...")
    sys.exit(1)

response_json = response.json()
post_policy_form_data = response_json["URL"]["fields"]
multipart_form_data = {
    **post_policy_form_data,
    "file": (post_policy_form_data["key"], open(filename, "r")),
}

# Upload data
print("Uploading data")
upload_response = requests.post(response_json["URL"]["url"], files=multipart_form_data)
print(upload_response.status_code, upload_response.text)
print(f"Waiting for {data_product_name}.{table_name} to create in athena")
time.sleep(10)

# Check for created table
try:
    glue.get_table(DatabaseName=data_product_name, Name=table_name)
    print(f"{data_product_name}.{table_name} found in glue")
except Exception as e:
    raise e

# Clean up created table
try:
    glue.delete_table(DatabaseName=data_product_name, Name=table_name)
    print(f"{data_product_name}.{table_name} deleted from glue")
except Exception as e:
    raise e
