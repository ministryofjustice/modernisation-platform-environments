import json


def construct_response(query, query_result):
    return {
        "statusCode": 200,
        "headers": { "Content-Type": "application/json" },
        "body": json.dumps({
            "query": query,
            "query_result": query_result
        }),
        "isBase64Encoded": False
    }


def construct_error(err):
    return {
        "statusCode": 400,
        "headers": { "Content-Type": "application/json" },
        "body": json.dumps({
            "message": str(err)
        }),
        "isBase64Encoded": False
    }