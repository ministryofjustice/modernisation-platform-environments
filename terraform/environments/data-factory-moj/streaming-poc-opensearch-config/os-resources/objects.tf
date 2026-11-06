resource "null_resource" "saved_objects" {
  for_each = local.saved_objects
  triggers = {
    form_data_hash = filemd5("saved-objects/${each.value}")
  }
  provisioner "local-exec" {
    command = <<-EOT
curl  \
  -k -X POST "https://localhost:9200/_dashboards/api/saved_objects/_import?overwrite=true" \
  -H 'osd-xsrf: true' \
  -H 'Content-Type: multipart/form-data' \
  -u '${local.os_creds.username}:${local.os_creds.password}' \
  --form file=@saved-objects/${each.value}
EOT
  }

  depends_on = [
    opensearch_index.correlated_event,
    opensearch_index.geo_fence_events,
    opensearch_index.radar_event_path,
    opensearch_index.radar_event_position,
    opensearch_index.radar_heartbeat_event,
    opensearch_index.radar_l01,
    opensearch_index.radar_l02,
    opensearch_index.radar_l03,
    opensearch_index.voice_cdr_events
  ]
}
