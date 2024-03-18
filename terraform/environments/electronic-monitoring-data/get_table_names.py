import boto3


def get_table_and_database_names():
    client = boto3.client("glue")

    response_get_databases = client.get_databases()

    database_list = response_get_databases["DatabaseList"]
    names = {}
    for database_dict in database_list:

        database_name = database_dict["Name"]
        names[database_name] = []

        response_get_tables = client.get_tables(DatabaseName=database_name)
        table_list = response_get_tables["TableList"]

        for table_dict in table_list:
            names[database_name].append(table_dict["Name"])
        return names


def lambda_handler(event, context):
    names = get_table_and_database_names()
    args = [
        {"database_name": database_name, "table_name": table_name}
        for database_name in names
        for table_name in names[database_name]
    ]
    return {"statusCode": 200, "arguments": args}
