import os
import json
import gzip
import io
import time
import datetime
from urllib.parse import unquote_plus

import boto3

logs = boto3.client("logs")
s3 = boto3.client("s3")

LOG_GROUP = os.environ["LOG_GROUP_NAME"]
CHUNK_SIZE = 1000  # conservative; lower if log lines can be large
MAX_AGE_MS = 14 * 24 * 3600 * 1000
MAX_FUTURE_MS = 2 * 3600 * 1000


def handler(event, context):
    now_ms = int(time.time() * 1000)

    for rec in _iter_s3_records(event):
        bucket = rec["s3"]["bucket"]["name"]
        key = unquote_plus(rec["s3"]["object"]["key"])
        stream_name = key[-512:]  # ensure <= 512 chars

        # 1) Read the object (gz or plain)
        obj = s3.get_object(Bucket=bucket, Key=key)
        body = obj["Body"]
        is_gz = (obj.get("ContentEncoding", "").lower() == "gzip") or key.endswith(".gz")

        # Build events: [{"timestamp": <ms>, "message": <line>}, ...]
        events = []
        for line in _iter_lines(body, gz=is_gz):
            line = line.strip()
            if not line:
                continue

            ts_ms = _extract_ts_ms(line)
            if ts_ms is None:
                continue  # skip lines without a usable timestamp

            # Respect CloudWatch Logs time bounds
            if ts_ms < (now_ms - MAX_AGE_MS) or ts_ms > (now_ms + MAX_FUTURE_MS):
                continue

            events.append({"timestamp": ts_ms, "message": line})

        if not events:
            continue

        events.sort(key=lambda e: e["timestamp"])

        # 2) Ensure stream exists (no log group creation here—keep it minimal)
        try:
            logs.create_log_stream(logGroupName=LOG_GROUP, logStreamName=stream_name)
        except logs.exceptions.ResourceAlreadyExistsException:
            pass

        # 3) Ship in chunks, with one simple sequence-token retry path
        seq = _get_upload_seq_token(LOG_GROUP, stream_name)
        i = 0
        while i < len(events):
            batch = events[i : i + CHUNK_SIZE]
            args = {
                "logGroupName": LOG_GROUP,
                "logStreamName": stream_name,
                "logEvents": batch,
            }
            if seq:
                args["sequenceToken"] = seq
            try:
                resp = logs.put_log_events(**args)
                seq = resp.get("nextSequenceToken")
                i += len(batch)
            except logs.exceptions.InvalidSequenceTokenException:
                seq = _get_upload_seq_token(LOG_GROUP, stream_name)  # refresh once

    return {"status": "ok"}


def _iter_s3_records(event):
    """
    Yield S3 event records from:
      - Direct S3 event (rec contains 's3')
      - SQS with raw S3 body (rec['body'] has {"Records":[...]})
      - SQS with SNS envelope (rec['body'] has {"Message":"{...Records...}"})
    """
    for rec in event.get("Records", ()):
        # Already an S3 event (e.g., direct S3 invoke)
        if "s3" in rec:
            yield rec
            continue

        # Likely SQS → body is JSON
        body = rec.get("body")
        if not body:
            continue
        try:
            outer = json.loads(body)
        except Exception:
            continue

        # SNS-wrapped? (Message is a JSON string of the original S3 event)
        if isinstance(outer, dict) and "Message" in outer and isinstance(outer["Message"], str):
            try:
                inner = json.loads(outer["Message"])
            except Exception:
                continue
        else:
            inner = outer

        for s3rec in inner.get("Records", []) or []:
            if "s3" in s3rec:
                yield s3rec


def _iter_lines(body, gz: bool):
    """Yield UTF-8 lines from an S3 StreamingBody, supporting gzip."""
    if gz:
        # TextIOWrapper gives us str lines directly with the right decoding.
        with gzip.GzipFile(fileobj=body) as raw:
            for line in io.TextIOWrapper(raw, encoding="utf-8", errors="replace"):
                yield line
    else:
        for b in body.iter_lines(chunk_size=64 * 1024):
            yield b.decode("utf-8", errors="replace")


def _extract_ts_ms(line: str):
    """Return event time in epoch milliseconds from Network Firewall EVE JSON."""
    try:
        obj = json.loads(line)
    except json.JSONDecodeError:
        return None

    # Prefer epoch seconds in top-level event_timestamp (often a string)
    et = obj.get("event_timestamp")
    if et is not None:
        try:
            return int(float(et) * 1000)  # preserve fractional seconds
        except (TypeError, ValueError):
            pass

    # Fallback to ISO8601 inside event.timestamp, e.g. 2025-09-29T17:20:03.799527+0000 or ...Z
    ts = (obj.get("event") or {}).get("timestamp")
    if ts:
        # Normalize 'Z' to '+0000' so strptime yields an aware datetime
        if ts.endswith("Z"):
            ts = ts[:-1] + "+0000"
        for fmt in ("%Y-%m-%dT%H:%M:%S.%f%z", "%Y-%m-%dT%H:%M:%S%z"):
            try:
                dt = datetime.datetime.strptime(ts, fmt)
                return int(dt.timestamp() * 1000)
            except ValueError:
                continue
    return None


def _get_upload_seq_token(log_group, stream_name):
    """Return current uploadSequenceToken (or None) for the stream."""
    resp = logs.describe_log_streams(
        logGroupName=log_group,
        logStreamNamePrefix=stream_name,
        limit=1,
    )
    streams = resp.get("logStreams") or []
    if streams and streams[0]["logStreamName"] == stream_name:
        return streams[0].get("uploadSequenceToken")
    return None
