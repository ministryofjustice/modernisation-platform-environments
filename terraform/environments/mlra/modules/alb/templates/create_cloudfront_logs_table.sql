CREATE EXTERNAL TABLE IF NOT EXISTS `cloudfront_logs`(
  `date` date,
  `time` string,
  `location` string,
  `bytes` bigint,
  `request_ip` string,
  `method` string,
  `host` string,
  `uri` string,
  `status` int,
  `referrer` string,
  `user_agent` string,
  `query_string` string,
  `cookie` string,
  `result_type` string,
  `request_id` string,
  `host_header` string,
  `request_protocol` string,
  `request_bytes` bigint,
  `time_taken` float,
  `xforwarded_for` string,
  `ssl_protocol` string,
  `ssl_cipher` string,
  `response_result_type` string,
  `http_version` string,
  `fle_status` string,
  `fle_encrypted_fields` int,
  `c_port` int,
  `time_to_first_byte` float,
  `x_edge_detailed_result_type` string,
  `sc_content_type` string,
  `sc_content_len` bigint,
  `sc_range_start` bigint,
  `sc_range_end` bigint)
ROW FORMAT DELIMITED
  FIELDS TERMINATED BY '\t'
STORED AS INPUTFORMAT
  'org.apache.hadoop.mapred.TextInputFormat'
OUTPUTFORMAT
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  's3://${bucket}/mlra/'
TBLPROPERTIES (
  'skip.header.line.count'='2')