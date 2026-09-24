import json
import time

from botocore.exceptions import ClientError


class TerminalOutcomes:
    def __init__(self, table, expiry_seconds):
        self.table = table
        self.expiry_seconds = expiry_seconds

    def get(self, request):
        response = self.table.get_item(
            Key={"id": f"terminal:{request.action_execution_id}"},
            ConsistentRead=True,
        )
        item = response.get("Item")
        if item is None:
            return None
        if item["envelopeId"] != request.envelope_id:
            raise ValueError("An action execution ID was reused for another request")
        return item

    def record(self, request, detail):
        item = {
            "id": f"terminal:{request.action_execution_id}",
            "envelopeId": request.envelope_id,
            "detail": json.dumps(detail, separators=(",", ":")),
            "expiration": int(time.time()) + self.expiry_seconds,
        }
        try:
            self.table.put_item(Item=item, ConditionExpression="attribute_not_exists(id)")
            return item
        except ClientError as error:
            if error.response.get("Error", {}).get("Code") != "ConditionalCheckFailedException":
                raise
            existing = self.get(request)
            if existing is None:
                raise RuntimeError("Terminal outcome disappeared after a competing write") from error
            return existing

    def publish(self, request, item, publish_detail):
        if item.get("published"):
            return
        publish_detail(request, json.loads(item["detail"]))
        self.table.update_item(
            Key={"id": item["id"]},
            UpdateExpression="SET #published = :published",
            ConditionExpression="attribute_exists(id) AND envelopeId = :envelopeId",
            ExpressionAttributeNames={"#published": "published"},
            ExpressionAttributeValues={
                ":published": True,
                ":envelopeId": request.envelope_id,
            },
        )