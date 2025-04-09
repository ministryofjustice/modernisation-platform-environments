#!/usr/bin/env python3
import sys
import json
import hmac
import hashlib
import base64

def main():
    params = json.load(sys.stdin)
    key = params["secret_access_key"]
    region = params["region"]

    message = "SendRawEmail"
    version = b"AWS4"
    date = b"11111111"

    k_date = hmac.new((version + key.encode('utf-8')), date, hashlib.sha256).digest()
    k_region = hmac.new(k_date, region.encode('utf-8'), hashlib.sha256).digest()
    k_service = hmac.new(k_region, b"ses", hashlib.sha256).digest()
    k_signing = hmac.new(k_service, message.encode('utf-8'), hashlib.sha256).digest()

    smtp_password = base64.b64encode(k_signing).decode('utf-8')
    print(json.dumps({"smtp_password": smtp_password}))

if __name__ == "__main__":
    main()