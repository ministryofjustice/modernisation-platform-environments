import json
import os
import sys
from typing import Any
import boto3
import requests


data_product_name = "mitch_example_prison_data_product"
table_name = "mitch_example_prison_table"
base_url = "https://hsolkci589.execute-api.eu-west-2.amazonaws.com/development"
schema_url = f"/data-product/{data_product_name}"
url = base_url + schema_url
glue_client = boto3.client("glue")
s3_client = boto3.client("s3")

test_metadata_with_schemas = {
    "name": "test_product",
    "description": "just testing the metadata json validation/registration",
    "domain": "MoJ",
    "dataProductOwner": "matthew.laverty@justice.gov.uk",
    "dataProductOwnerDisplayName": "matt laverty",
    "email": "matthew.laverty@justice.gov.uk",
    "status": "draft",
    "retentionPeriod": 3000,
    "dpiaRequired": False,
    "schemas": ["schema0", "schema1", "schema2"],
}

test_schema: dict[str, Any] = {
    "tableDescription": "table has schema to pass test",
    "columns": [
        {
            "name": "col_1",
            "type": "bigint",
            "description": "ABCDEFGHIJKLMNOPQRSTUVWXY",
        },
        {"name": "col_2", "type": "tinyint", "description": "ABCDEFGHIJKL"},
        {
            "name": "col_3",
            "type": "int",
            "description": "ABCDEFGHIJKLMNOPQRSTUVWX",
        },
        {"name": "col_4", "type": "smallint", "description": "ABCDEFGHIJKLMN"},
    ],
}

buckets = {
    "metadata": "metadata-development20231011135450514100000004",
    "data": "data-development20231011135451999500000005",
}


try:
    auth_token = json.loads(os.environ["API_AUTH"])
    auth_token = auth_token["auth-token"]
except KeyError:
    print("API_AUTH environment variable should be set to a json containing auth-token")
    sys.exit(1)

headers = {"authorizationToken": auth_token}

versions = ["v1.0", "v1.1", "v1.2"]


def create_metadata_files():
    print("Creating metadata files")
    for version in versions:
        s3_client.put_object(
            Body=json.dumps(test_metadata_with_schemas),
            Bucket=buckets["metadata"],
            Key=f"{data_product_name}/{version}/metadata.json",
            ACL="bucket-owner-full-control",
        )


def create_schema_files():
    print("Creating schema files")
    for i in range(3):
        for version in versions:
            s3_client.put_object(
                Body=json.dumps(test_schema),
                Bucket=buckets["metadata"],
                Key=f"{data_product_name}/{version}/schema{i}/schema.json",
                ACL="bucket-owner-full-control",
            )


def create_data_files():
    print("Creating data files")
    for version in versions:
        for i in range(10):
            s3_client.put_object(
                Bucket=buckets["data"],
                Key=f"curated/{data_product_name}/{version}/schema0/curated-file-{str(i)}.json",
                Body=json.dumps({"content": f"{i}"}),
                ACL="bucket-owner-full-control",
            )
            s3_client.put_object(
                Bucket=buckets["data"],
                Key=f"raw/{data_product_name}/{version}/schema0/raw-file-{str(i)}.json",
                Body=json.dumps({"content": f"{i}"}),
                ACL="bucket-owner-full-control",
            )
            s3_client.put_object(
                Bucket=buckets["data"],
                Key=f"fail/{data_product_name}/{version}/schema0/fail-file-{str(i)}.json",
                Body=json.dumps({"content": f"{i}"}),
                ACL="bucket-owner-full-control",
            )


def create_glue_database():
    print("Creating glue database...")
    try:
        glue_client.create_database(DatabaseInput={"Name": data_product_name})
    except glue_client.exceptions.AlreadyExistsException:
        print("database already exists...")


def create_glue_tables():
    print("Creating glue tables...")
    for i in range(3):
        try:
            glue_client.create_table(
                DatabaseName=data_product_name, TableInput={"Name": f"schema{i}"}
            )
        except glue_client.exceptions.AlreadyExistsException:
            print("Glue table already exists...")


def setup():
    create_metadata_files()
    create_schema_files()
    create_data_files()
    create_glue_database()
    create_glue_tables()


def call_delete_data_product_api():
    # Delete schema request
    response = requests.delete(
        url=url,
        headers=headers,
    )
    if response.status_code != 200:
        print(f"Error. Status code: {response.status_code}")
        print(f"Error. Response: {response.text}")
        print("Exiting...")
        sys.exit(1)

    response_json = response.json()
    print(response_json)


def main():
    setup()
    call_delete_data_product_api()


if __name__ == "__main__":
    main()
