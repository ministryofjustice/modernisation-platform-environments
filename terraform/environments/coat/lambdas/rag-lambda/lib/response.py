import json


def construct_response(query, query_result):
    return json.dumps(
        {
            "status": 200,
            "data": {
                "query": query,
                "query_result": query_result
            }
        }
    )


def construct_error(err):
    return json.dumps(
        {
            "status": 400,
            "message": str(err)
        }
    )