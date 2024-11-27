#!/usr/bin/env bash

# Get IP address via Cloudflare
ip="$(curl --silent https://cloudflare.com/cdn-cgi/trace | awk -F= '/ip=/{print $2}')"

# Return it as a JSON object
echo "{\"ip\": \"${ip}\"}"
