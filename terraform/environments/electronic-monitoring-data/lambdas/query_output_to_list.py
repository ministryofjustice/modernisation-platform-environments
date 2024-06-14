def handler(event, context):
    data = event["ResultSet"]["Rows"][1:]
    output_list = [{row["Data"][0]["VarCharValue"]: row["Data"][1]["VarCharValue"]} for row in data]
    return output_list
