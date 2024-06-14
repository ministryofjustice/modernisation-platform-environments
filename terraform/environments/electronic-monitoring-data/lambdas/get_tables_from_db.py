import os
import logging
import boto3
import json

glue = boto3.client("glue")

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

def handler(event, context):
    db_name = event.get("db_name")
    response = glue.get_tables(DatabaseName=db_name)
    tables = response['TableList']
    table_names = [{db_name: table['Name']} for table in tables]
    return table_names