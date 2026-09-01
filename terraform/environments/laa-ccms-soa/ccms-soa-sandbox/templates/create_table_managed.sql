CREATE EXTERNAL TABLE IF NOT EXISTS nlb_managed_logs (
            type string,
            version string,
            time string,
            elb string,
            listener_id string,
            client_ip string,
            client_port int,
            target_ip string,
            target_port int,
            tcp_connection_time_ms double,
            tls_handshake_time_ms double,
            received_bytes bigint,
            sent_bytes bigint,
            incoming_tls_alert int,
            cert_arn string,
            certificate_serial string,
            tls_cipher_suite string,
            tls_protocol_version string,
            tls_named_group string,
            domain_name string,
            alpn_fe_protocol string,
            alpn_be_protocol string,
            alpn_client_preference_list string,
            tls_connection_creation_time string
            )
            ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.RegexSerDe'
            WITH SERDEPROPERTIES (
            'serialization.format' = '1',
            'input.regex' = 
            '([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*):([0-9]*) ([^ ]*):([0-9]*) ([-.0-9]*) ([-.0-9]*) ([-0-9]*) ([-0-9]*) ([-0-9]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ?([^ ]*)?( .*)?'
            )
  LOCATION 's3://${bucket}/${key}/AWSLogs/${account_id}/elasticloadbalancing/${region}/'
  TBLPROPERTIES
  (
    "projection.enabled" = "true",
    "projection.day.type" = "date",
    "projection.day.range" = "2023/02/14,NOW",
    "projection.day.format" = "yyyy/MM/dd",
    "projection.day.interval" = "1",
    "projection.day.interval.unit" = "DAYS",
    "storage.location.template" = "s3://${bucket}/${key}/AWSLogs/${account_id}/elasticloadbalancing/${region}/$${day}"
  )