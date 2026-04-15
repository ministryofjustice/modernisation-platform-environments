import json


def parse_request_body(request):
    request_body_json = request.get("body", {})

    return json.loads(request.get("body", {}))