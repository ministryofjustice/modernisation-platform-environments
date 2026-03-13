{
  "Comment": "DNS update via null_resource based on backend health",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${record_name}",
        "Type": "A",
        "TTL": 60,
        "ResourceRecords": [
          {
            "Value": "REPLACE_IP"
          }
        ]
      }
    }
  ]
}
