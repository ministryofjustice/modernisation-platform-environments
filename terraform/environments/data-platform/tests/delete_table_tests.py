import sys

import boto3
import requests


data_product_name = "example_prison_data_product"
table_name = "testing"
base_url = "https://hsolkci589.execute-api.eu-west-2.amazonaws.com/development"
schema_url = f"/data-product/{data_product_name}/table/{table_name}"
url = base_url + schema_url
headers = {"authorizationToken": "placeholder"}
glue = boto3.client("glue")

# Delete schema request
response = requests.delete(
    url=url,
    headers=headers,
)

if response.status_code != 200:
    print(f"Error deleting data product schema. Status code: {response.status_code}")
    print(f"Error deleting data product schema. Response: {response.text}")
    print("Exiting...")
    sys.exit(1)

response_json = response.json()

# Evaluate response TBC

# Check for existence/non existence of tables? TBC
