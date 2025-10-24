-- The following query counts the number of TLS connections less than TLSv1.3
-- grouped by TLS protocol version and client IP address from NLB logs

SELECT tls_protocol_version,
         COUNT(tls_protocol_version) AS 
         num_connections,
         client_ip
FROM "nlb_managed_logs"
WHERE from_iso8601_timestamp(time) > current_timestamp - interval '1' day 
and tls_protocol_version < 'tlsv13'
GROUP BY tls_protocol_version, client_ip
LIMIT 100;