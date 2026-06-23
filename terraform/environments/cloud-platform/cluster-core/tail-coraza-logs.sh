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

# Clear the terminal screen and show fresh logs from now on
clear

stern "$selector" -n "$namespace" -c "$container" -o raw --since 1m | jq -Rr '
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
      # Bind defaults to variables first to avoid double-quotes inside \() interpolation.
      ($line.transaction.producer.rule_engine // "unknown") as $engine |
      ($line.transaction.response.status   // 0)           as $status |
      ($line.transaction.is_interrupted    // false)        as $interrupted |
      ($line.transaction.request.uri       // "")           as $uri |
      "------------------------------------------------------------",
      "time=\($line.transaction.timestamp) id=\($line.transaction.id)",
      "verdict=\(verdict($line.transaction)) status=\($status) interrupted=\($interrupted) engine=\($engine)",
      "client=\($line.transaction.client_ip):\($line.transaction.client_port) host=\($line.transaction.server_id)",
      "request=\($line.transaction.request.method) \($uri | trunc(180))",
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
      # Skip duplicate info/warn lines; the structured transaction entry is easier to read.
      empty
    elif $line.response_code? then
      ($line.response_code_details // "") as $details |
      ($line["x-request-id"]       // "unknown") as $rid |
      ($line[":authority"]         // "") as $authority |
      ($line.route_name            // "") as $route |
      ($line["x-envoy-origin-path"] // "") as $path |
      "access verdict=\(access_verdict($line)) status=\($line.response_code) details=\($details) id=\($rid)",
      "host=\($authority) route=\($route | trunc(120)) path=\($path | trunc(120))",
      ""
    else
      # Ignore non-JSON/noise lines (including literal "null" output) for cleaner tails.
      empty
    end
'