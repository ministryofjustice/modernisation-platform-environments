-- The following query counts the number of HTTP GET requests received by the load balancer grouped by the client IP address

SELECT COUNT(request_verb) AS
 count,
 request_verb,
 client_ip
FROM alb_adaptor_internal_logs
GROUP BY request_verb, client_ip
LIMIT 100;