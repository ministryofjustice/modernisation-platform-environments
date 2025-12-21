import time
import boto3


class AthenaService:
    def __init__(self, database):
        self.client = boto3.client("athena", region_name="eu-west-2")

        self.database = database
        self.workgroup = "primary"
        self.output_location = "s3://coat-development-athena-output-clickops/Unsaved"


    def start_query(self, query):
        response = self.client.start_query_execution(
            QueryString=query,
            QueryExecutionContext={"Database": self.database},
            ResultConfiguration={"OutputLocation": self.output_location},
            WorkGroup=self.workgroup
        )

        return response.get("QueryExecutionId", "")


    def wait_for_query(self, query_execution_id):
        while True:
            response = self.client.get_query_execution(QueryExecutionId=query_execution_id)

            state = response.get("QueryExecution", {}).get("Status", {}).get("State", "")

            if state == "SUCCEEDED":
                return
            elif state in ("FAILED", "CANCELLED"):
                reason = response.get("QueryExecution", {}).get("Status", {}).get("StateChangeReason", "")

                raise RuntimeError(f"Athena query {state}: {reason}")

            time.sleep(2)


    def get_results(self, query_execution_id):
        paginator = self.client.get_paginator("get_query_results")
        
        pages = paginator.paginate(
            QueryExecutionId=query_execution_id,
            PaginationConfig={"PageSize": 1000},
        )

        columns = []
        rows = []

        for page in pages:
            if columns == []:
                columns = [
                    column.get("Name", "") for column in page.get("ResultSet", {}).get("ResultSetMetadata", {}).get("ColumnInfo", [])
                ]

            for row in page.get("ResultSet", {}).get("Rows", []):
                values = [field.get("VarCharValue", "") for field in row.get("Data", [])]

                key_values = dict(zip(columns, values))

                rows.append(key_values)

        return rows[1:]


    def run_query(self, query):
        query_execution_id = self.start_query(query)

        self.wait_for_query(query_execution_id)
        
        return self.get_results(query_execution_id)


    def test_athena_service(self):
        table = "fct_daily_cost"

        query = f"SELECT * FROM {table} LIMIT 10;"

        athena_response = self.run_query(query)

        print("Test Athena Service")

        for row in athena_response:
            print(row)
