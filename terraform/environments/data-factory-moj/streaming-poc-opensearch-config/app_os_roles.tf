resource "null_resource" "run_role_mappings" {
  for_each = local.os_mappings
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOT
      TASK_ARN=$(AWS_PROFILE=moj-sandbox aws ecs list-tasks \
        --cluster "streaming-pov-ecs-cluster" \
        --service-name "streaming-pov-ecs-sdg" \
        --desired-status "RUNNING" \
        --query "taskArns[0]" \
        --region "eu-west-2" \
        --output text)

      if [ "$TASK_ARN" = "None" ] || [ -z "$TASK_ARN" ]; then
        echo "Error: No running ECS tasks found for this service!"
        exit 1
      fi

      script -q /dev/null aws ecs execute-command \
        --cluster "streaming-pov-ecs-cluster" \
        --task "$TASK_ARN" \
        --container "streaming-pov-ecs-sdg" \
        --interactive \
        --region "eu-west-2" \
        --command "sh -c 'echo ${local.escaped_payloads[each.key]} > /tmp/rolemapping_payload.json; /usr/bin/curl -k -X PUT 'https://${data.aws_opensearch_domain.moj_domain.endpoint}/_plugins/_security/api/rolesmapping/${each.key}' -H \"osd-xsrf: true\" -H \"Content-Type: application/json\" -u '${local.os_creds.username}:${local.os_creds.password}' -d @/tmp/rolemapping_payload.json > /tmp/rolemapping.out'"

      sleep 10
EOT
  }
}
