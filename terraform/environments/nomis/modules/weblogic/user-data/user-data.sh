#!/bin/bash

# Make sure /dev/xvdb is mounted to /u01 (fstab working intermittently)
mount -a

# Create nomis_weblogic service
chkconfig --add nomis_weblogic
chkconfig --level 3 nomis_weblogic on

# Get instance-id for autoscaling lifecycle hook
INSTANCE_ID=$(curl http://instance-data/latest/meta-data/instance-id)

# Check variables are set and run weblogic setup script
# USAGE
# [-d] Use default credentials for database and Weblogic admin console
# [-e <ENV> e.g. T1]
# [-h <DB_HOSTNAME>]
if [[ -n ${ENV} ]] && [[ -n ${DB_HOSTNAME} ]] && [[ ${USE_DEFAULT_CREDS} = "false" ]]; then
  su -c "bash /u01/software/weblogic/weblogic-setup.sh -d -e ${ENV} -h ${DB_HOSTNAME}" - oracle
elif [[ -n ${DB_HOSTNAME} ]] && [[ ${USE_DEFAULT_CREDS} = "true" ]]; then
  su -c "bash /u01/software/weblogic/weblogic-setup.sh -d -h ${DB_HOSTNAME}" - oracle
else
  echo "Error: Environment variables undefined"
  # Send lifecycle failure notification - instance cannot enter warm pool or ASG
  aws autoscaling complete-lifecycle-action --lifecycle-action-result ABANDON --instance-id $INSTANCE_ID --lifecycle-hook-name ${LIFECYCLE_HOOK_NAME} --auto-scaling-group-name ${AUTO_SCALING_GROUP_NAME} --region ${REGION}
  exit 1
fi

# Send lifecycle success notification to indicate instance is ready to transition to "Warmed:stopped" state and enter warm pool, or directly to ASG
aws autoscaling complete-lifecycle-action --lifecycle-action-result CONTINUE --instance-id $INSTANCE_ID --lifecycle-hook-name ${LIFECYCLE_HOOK_NAME} --auto-scaling-group-name ${AUTO_SCALING_GROUP_NAME} --region ${REGION}

# Add script that triggers lifecycle hook when instance is restarted (i.e. when exiting the warm pool)
# Always trigger CONTINUE, loadbalancer health checks will determine if service up
cat > /usr/local/bin/autoscaling-lifecycle-hook.sh << 'EOF'
#!/bin/bash
# Added by cloud-init user-data script
# Triggers an AWS auto-scaling group lifecycle hook to indicate that the instance is in a ready state
INSTANCE_ID=$(curl http://instance-data/latest/meta-data/instance-id)
aws autoscaling complete-lifecycle-action --lifecycle-action-result CONTINUE --instance-id $INSTANCE_ID --lifecycle-hook-name ${LIFECYCLE_HOOK_NAME} --auto-scaling-group-name ${AUTO_SCALING_GROUP_NAME} --region ${REGION}
EOF

chmod u+x /usr/local/bin/autoscaling-lifecycle-hook.sh

# Add to cron.d to run at boot and make sure crond is enabled
echo "@reboot root /usr/local/bin/autoscaling-lifecycle-hook.sh" > /etc/cron.d/autoscaling-lifecycle-hook
chkconfig crond on
