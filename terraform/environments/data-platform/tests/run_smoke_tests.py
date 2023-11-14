import base64
import hashlib
import json
import os
import sys
import time

import boto3
import requests

filename = "test_data.csv"
data_product_name = "example_prison_data_product"
table_name = "testing"
base_url = "https://hsolkci589.execute-api.eu-west-2.amazonaws.com/development"
glue = boto3.client("glue")

try:
    auth_token = json.loads(os.environ["API_AUTH"])
    auth_token = auth_token["auth-token"]
except KeyError:
    print("API_AUTH environment variable should be set to a json containing auth-token")
    sys.exit(1)


def md5_hash_file_contents(file) -> str:
    """This holds the file in memory to hash so
    will be unsuitable for large files"""
    with open(file, "r") as tempfile:
        body = tempfile.read()
    md = hashlib.md5(body.encode("utf-8")).digest()
    contents_md5 = base64.b64encode(md).decode("utf-8")

    return contents_md5

class APIClient:
    def __init__(self, base_url, auth_token):
        self.table_url = base_url + f"/data-product/{data_product_name}/table/{table_name}"
        self.data_product_url = base_url + f"/data-product/{data_product_name}"
        self.register_url = base_url + f"/data-product/register"
        self.presigned_url = base_url + f"/data-product/{data_product_name}/table/{table_name}/upload"
        self.headers = {"authorizationToken": auth_token}
        
    def register(self):
        print("Registering data product...")

        metadata = {
            "name": "example_prison_data_product",
            "description": "just testing the metadata json validation/registration",
            "domain": "MoJ",
            "dataProductOwner": "matthew.laverty@justice.gov.uk",
            "dataProductOwnerDisplayName": "matt laverty",
            "email": "matthew.laverty@justice.gov.uk",
            "status": "draft",
            "dpiaRequired": False,
            "retentionPeriod": 3650
        }

        return requests.post(
            url=self.register_url,
            headers=self.headers,
            json={
                "metadata": metadata
            }
        )

    def delete_data_product(self):
        print("Deleting data product...")
        return requests.delete(
            url=self.data_product_url,
            headers=self.headers,
        )

    def create_schema(self):
        print("Creating a schema...")
        return requests.post(
            url=self.table_url + "/schema",
            headers=self.headers,
            json={
                "schema": {
                    "tableDescription": "just a test table",
                    "columns": [
                        {"name": "col_0", "type": "double", "description": "just a test column"},
                        {"name": "col_1", "type": "double", "description": "just a test column"},
                        {"name": "col_2", "type": "double", "description": "just a test column"},
                        {"name": "col_3", "type": "double", "description": "just a test column"},
                    ]
                }
            }
        )

    def upload_file(self):
        file_md5_hash = md5_hash_file_contents(filename)

        body = {
            "filename": filename,
            "contentMD5": file_md5_hash,
        }

        # Get presigned url
        response = requests.post(
            url=self.presigned_url,
            json=body,
            headers=self.headers,
        )

        if response.status_code != 200:
            print(f"Error getting presigned url. Status code: {response.status_code}")
            print(f"Error getting presigned url. Response: {response.text}")
            raise Exception('Error getting presigned URL')
        
        response_json = response.json()
        post_policy_form_data = response_json["URL"]["fields"]
        multipart_form_data = {
            **post_policy_form_data,
            "file": (post_policy_form_data["key"], open(filename, "r")),
        }

        # Upload data
        print("Uploading data")
        return requests.post(response_json["URL"]["url"], files=multipart_form_data)


def run_test(client):
    # register_response = client.register()
    # if register_response.status_code != 200:
    #     print(f"Unable to create data product. Code: {register_response.status_code}")
    #     print(f"Error creating data product. Response: {register_response.text}")
    #     return

    # schema_response = client.create_schema()
    # if schema_response.status_code != 200:
    #     print(f"Unable to create schema. Code: {schema_response.status_code}")
    #     print(f"Error creating schema. Response: {schema_response.text}")
    #     return

    upload_response = client.upload_file()
    print(upload_response.status_code, upload_response.text)
    print(f"Waiting for {data_product_name}.{table_name} to create in athena")
    time.sleep(10)

    # Check for created table
    try:
        glue.get_table(DatabaseName=data_product_name, Name=table_name)
        print(f"{data_product_name}.{table_name} found in glue")
    except Exception as e:
        raise e


try:
    client = APIClient(base_url, auth_token)
    run_test(client)
finally:
    # response = client.delete_data_product()
    # if response.status_code != 200:
    #     print(f"Unable to delete data product code: {response.status_code}")
    #     print(f"Error deleting data product. Response: {response.text}")
    pass