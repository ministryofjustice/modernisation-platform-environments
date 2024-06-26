#!/bin/bash
# Any generic post ansible steps, e.g. calling lifecycle hook
set -e
PATH=$PATH:/usr/local/bin

main() {
  # call lifecycle script if one has been configured by ansible
  if [[ -x /usr/local/bin/autoscaling-lifecycle-ready-hook.sh ]]; then
    echo "# running: /usr/local/bin/autoscaling-lifecycle-ready-hook.sh"
    /usr/local/bin/autoscaling-lifecycle-ready-hook.sh
  else
    # otherwise, check if part of lifecycle.
    token=$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    state=$(curl -f -sS -H "X-aws-ec2-metadata-token: $token" http://169.254.169.254/latest/meta-data/autoscaling/target-lifecycle-state 2>/dev/null) || exitcode=$?
    if [[ $exitcode -eq 0 ]]; then
      echo "# no autoscaling lifecycle script found, run aws autoscaling complete-lifecycle-action --lifecycle-action-result ABANDON"
      instance_id=$(curl -sS -H "X-aws-ec2-metadata-token: $token" http://169.254.169.254/latest/meta-data/instance-id)
      region=$(curl -sS -H "X-aws-ec2-metadata-token: $token" http://169.254.169.254/latest/meta-data/placement/region)
      name=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$instance_id" "Name=key,Values=Name" --output=text | cut -f5)
      aws autoscaling complete-lifecycle-action --lifecycle-action-result "ABANDON" --instance-id "$instance_id" --lifecycle-hook-name "$name-ready-hook" --auto-scaling-group-name "$name" --region "$region" || true
    fi
  fi
}

echo "post-ec2provision.sh start" | logger -p local3.info -t user-data
main 2>&1 | logger -p local3.info -t user-data
echo "post-ec2provision.sh end" | logger -p local3.info -t user-data
