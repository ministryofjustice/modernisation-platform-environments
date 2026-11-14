import json
import logging
import os
import re
from datetime import datetime, timezone
from decimal import Decimal
from pathlib import Path

import boto3
from boto3.dynamodb.conditions import Attr

logger = logging.getLogger()
logger.setLevel(logging.INFO)

table = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])
PAGE = (Path(__file__).parent / "index.html").read_text(encoding="utf-8")

# Event names end up in a URL path (POST /events/{eventName}), so keep them URL safe
NAME_PATTERN = re.compile(r"^[A-Za-z0-9._-]{1,100}$")

# DynamoDB has no auto-increment: id 0 holds a counter and real events start at 1
COUNTER_ID = 0


def respond(status_code, body, content_type="application/json"):
    return {
        "statusCode": status_code,
        "headers": {
            "content-type": content_type,
            "cache-control": "no-store",
            "x-content-type-options": "nosniff",
            "content-security-policy": "default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; connect-src 'self'",
        },
        "body": body,
    }


def to_json(value):
    return json.dumps(value, default=lambda v: int(v) if isinstance(v, Decimal) else str(v))


def all_events():
    items = []
    kwargs = {"FilterExpression": Attr("id").gt(COUNTER_ID)}
    while True:
        result = table.scan(**kwargs)
        items.extend(result["Items"])
        if "LastEvaluatedKey" not in result:
            return sorted(items, key=lambda item: item["name"].lower())
        kwargs["ExclusiveStartKey"] = result["LastEvaluatedKey"]


def list_events(search):
    events = all_events()
    if search:
        events = [event for event in events if search.lower() in event["name"].lower()]
    return respond(200, to_json({"events": events}))


def create_event(body):
    try:
        name = json.loads(body or "{}").get("name")
    except (ValueError, AttributeError):
        return respond(400, to_json({"message": "Request body must be a JSON object"}))

    if not isinstance(name, str) or not NAME_PATTERN.match(name):
        return respond(
            400,
            to_json({"message": "Name must be 1-100 characters: letters, numbers, dot, dash or underscore"}),
        )
    # Not atomic: two simultaneous requests for the same new name could both succeed
    if any(event["name"] == name for event in all_events()):
        return respond(409, to_json({"message": f"Event {name} already exists"}))

    new_id = table.update_item(
        Key={"id": COUNTER_ID},
        UpdateExpression="ADD last_id :one",
        ExpressionAttributeValues={":one": 1},
        ReturnValues="UPDATED_NEW",
    )["Attributes"]["last_id"]
    now = datetime.now(timezone.utc).isoformat(timespec="seconds")
    item = {"id": new_id, "name": name, "created_ts": now, "updated_ts": now}
    table.put_item(Item=item, ConditionExpression="attribute_not_exists(id)")
    logger.info("Created event %s with id %s", name, new_id)
    return respond(201, to_json(item))


def lambda_handler(event, context):
    route = event["routeKey"]
    if route == "GET /":
        return respond(200, PAGE, "text/html; charset=utf-8")
    if route == "GET /api/events":
        search = (event.get("queryStringParameters") or {}).get("search", "")
        return list_events(search)
    if route == "POST /api/events":
        return create_event(event.get("body"))
    return respond(404, to_json({"message": "Not found"}))
