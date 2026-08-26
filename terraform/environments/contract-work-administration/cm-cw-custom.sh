#!/bin/bash

### /var/cw-custom.sh for Concurrent Manager - MP version

#  INSTANCE INFO
INSTANCE_META=http://169.254.169.254/latest/meta-data
INSTANCE_ID=$(curl $INSTANCE_META/instance-id)
INSTANCE_TYPE=$(curl $INSTANCE_META/instance-type)
IMAGE_ID=$(curl $INSTANCE_META/ami-id)
#  CLOUDWATCH NAMESPACE
CLOUDWATCH_NAMESPACE=CustomScript

#  GET METRICS
APACHE_STATUS=$(ps -ef | grep /CWA/app/oracle/ias/Apache/Apache/bin/httpd | grep -v grep >/dev/null 2>&1; echo $?)
APPS_CWA_STATUS=$(ps -ef | grep /CWA/app/oracle/806/bin/tnslsnr | grep -v grep >/dev/null 2>&1; echo $?)
f60srvm_STATUS=$(ps -ef | grep f60srvm | grep -v grep >/dev/null 2>&1; echo $?)

# SEND Apache Process Status ExitCode - should be 0
/usr/local/bin/aws cloudwatch put-metric-data                                                                       \
--metric-name apache_process                                                                                           \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                 \
--dimensions InstanceId="$INSTANCE_ID" \
--value "$APACHE_STATUS"                                                                                                \
--unit Count

# SEND APPS_CWA Process Status ExitCode - should be 0
/usr/local/bin/aws cloudwatch put-metric-data                                                                       \
--metric-name apps_cwa_process                                                                                           \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                 \
--dimensions InstanceId="$INSTANCE_ID" \
--value "$APPS_CWA_STATUS"                                                                                                \
--unit Count

# SEND f60srvm Process Status ExitCode - should be 0
/usr/local/bin/aws cloudwatch put-metric-data                                                                       \
--metric-name f60srvm_process                                                                                           \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                 \
--dimensions InstanceId="$INSTANCE_ID" \
--value "$f60srvm_STATUS"                                                                                                \
--unit Count