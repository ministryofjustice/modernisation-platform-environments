def lambda_handler(event, context):
    name = event["pathParameters"]["name"]
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "text/plain; charset=utf-8"},
        "body": f"Hello {name}",
    }
