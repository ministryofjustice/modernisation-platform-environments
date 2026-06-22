#!/usr/bin/env bash
set -euo pipefail

# Pretty-tail Coraza WAF logs from Envoy Gateway.
# Usage:
#   ./tail-coraza-logs.sh [namespace] [pod-selector] [container]
# Defaults:
#   namespace=envoy-gateway-system
#   pod-selector=envoy-envoy-gateway-system-eg
#   container=envoy

namespace="${1:-envoy-gateway-system}"
selector="${2:-envoy-envoy-gateway-system-eg}"
container="${3:-envoy}"

stern "$selector" -n "$namespace" -c "$container" -o raw | jq -Rr '
  def parse_rule:
    capture("\\[id \\\"(?<id>[0-9]+)\\\"\\].*\\[msg \\\"(?<msg>[^\\\"]+)\\\"\\].*\\[severity \\\"(?<severity>[^\\\"]+)\\\"]")? // null;

  def trunc($n):
    if . == null then ""
    elif (length > $n) then (.[0:$n] + "...")
    else .
    end;

  def verdict($tx):
    if ($tx.is_interrupted == true) then "BLOCKED"
    elif (($tx.response.status // 0) >= 400 and ($tx.response.status // 0) != 404) then "BLOCKED"
    else "DETECTED"
    end;

  def access_verdict($al):
    if (($al.response_code_details // "") | startswith("waf_")) then "BLOCKED"
    elif (($al.response_code // 0) >= 400 and ($al.response_code // 0) != 404) then "HTTP_ERROR"
    else "PASSTHROUGH"
    end;

  (fromjson? // {"raw": .}) as $line
  | if $line.transaction? then
      "------------------------------------------------------------",
      "time=\($line.transaction.timestamp) id=\($line.transaction.id)",
      "verdict=\(verdict($line.transaction)) status=\($line.transaction.response.status // 0) interrupted=\($line.transaction.is_interrupted // false) engine=\($line.transaction.producer.rule_engine // "unknown")",
      "client=\($line.transaction.client_ip):\($line.transaction.client_port) host=\($line.transaction.server_id)",
      "request=\($line.transaction.request.method) \(($line.transaction.request.uri // "" ) | trunc(180))",
      (
        $line.messages[]?.error_message
        | parse_rule
        | if . then
            "rule=\(.id) severity=\(.severity) msg=\(.msg)"
          else
            empty
          end
      ),
      ""
    elif $line.msg? then
      # Skip duplicate info/warn lines because the structured transaction entry is easier to read.
      empty
    elif $line.response_code? then
      "access verdict=\(access_verdict($line)) status=\($line.response_code // 0) details=\($line.response_code_details // "") id=\($line["x-request-id"] // "unknown")",
      "host=\($line[":authority"] // "") route=\(($line.route_name // "") | trunc(120)) path=\(($line["x-envoy-origin-path"] // "") | trunc(120))",
      ""
    else
      # Ignore non-JSON/noise lines (including literal "null" output) for cleaner tails.
      empty
    end
'