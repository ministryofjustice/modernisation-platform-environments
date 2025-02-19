#!/bin/bash

### /var/cw-custom.sh for Database - MP version

#  INSTANCE INFO
INSTANCE_META=http://169.254.169.254/latest/meta-data
INSTANCE_ID=$(curl $INSTANCE_META/instance-id)
INSTANCE_TYPE=$(curl $INSTANCE_META/instance-type)
IMAGE_ID=$(curl $INSTANCE_META/ami-id)
INSTANCE_NIC=eth0

ORADATA=xvdf
ORAARCH=xvdg
ORATMP=xvdh
ORAREDO=xvdi
ORACLE=xvdj
NFSShare=xvdk
ROOT=dm-0

REMOTE_VOLUME_DEV_ORADATA=/dev/$ORADATA
REMOTE_VOLUME_DEV_ORAARCH=/dev/$ORAARCH
REMOTE_VOLUME_DEV_ORATMP=/dev/$ORATMP
REMOTE_VOLUME_DEV_ORAREDO=/dev/$ORAREDO
REMOTE_VOLUME_DEV_ORACLE=/dev/$ORACLE
REMOTE_VOLUME_DEV_NFSSHARE=/dev/$NFSShare
REMOTE_VOLUME_DEV_ROOT=/dev/mapper/VolGroup00-LogVol00

REMOTE_VOLUME_PATH_ORADATA=/CWA/oradata
REMOTE_VOLUME_PATH_ORAARCH=/CWA/oraarch
REMOTE_VOLUME_PATH_ORATMP=/CWA/oratmp
REMOTE_VOLUME_PATH_ORAREDO=/CWA/oraredo
REMOTE_VOLUME_PATH_ORACLE=/CWA/oracle
REMOTE_VOLUME_PATH_NFSSHARE=/CWA/share
REMOTE_VOLUME_PATH_ROOT=/

REMOTE_VOLUME_FSTYPE=ext4

#  CLOUDWATCH NAMESPACE
CLOUDWATCH_NAMESPACE=CustomScript

#  GET METRICS

TOTAL_MEMORY=$(free -m | grep -i mem | awk '{print $2}')
USED_MEMORY_MINUS_CACHED=$(free -m | grep -i mem | awk '{print $3-$7}')
MEMORY_USAGE=$(expr $USED_MEMORY_MINUS_CACHED \* 100 / $TOTAL_MEMORY | awk '{printf "%.4f\t", substr($1,1)}')

DISK_USAGE=$(df | grep "$REMOTE_VOLUME_PATH" | awk '{printf "%.4f\t", substr($5, 1, length($5)-1)}')

MEMORY_USAGE=$(free -m | grep -i mem | awk '{print $3*100/$2}')

DISK_USAGE_ORADATA=$(df | grep "$REMOTE_VOLUME_DEV_ORADATA" | awk '{printf "%.4f\t", substr($5, 1, length($5)-1)}')
DISK_USAGE_ORAARCH=$(df | grep "$REMOTE_VOLUME_DEV_ORAARCH" | awk '{printf "%.4f\t", substr($5, 1, length($5)-1)}')
DISK_USAGE_ORATMP=$(df | grep "$REMOTE_VOLUME_DEV_ORATMP" | awk '{printf "%.4f\t", substr($5, 1, length($5)-1)}')
DISK_USAGE_ORAREDO=$(df | grep "$REMOTE_VOLUME_DEV_ORAREDO" | awk '{printf "%.4f\t", substr($5, 1, length($5)-1)}')
DISK_USAGE_ORACLE=$(df | grep "$REMOTE_VOLUME_DEV_ORACLE" | awk '{printf "%.4f\t", substr($5, 1, length($5)-1)}')
DISK_USAGE_NFSSHARE=$(df | grep "$REMOTE_VOLUME_DEV_NFSSHARE" | awk '{printf "%.4f\t", substr($5, 1, length($5)-1)}')
DISK_USAGE_ROOT=$(df | grep -A1 "$REMOTE_VOLUME_DEV_ROOT" | grep -v "$REMOTE_VOLUME_DEV_ROOT" | awk '{printf "%.4f\t", substr($4, 1, length($4)-1)}')

RX_DROPPED=$(netstat -i | grep eth0 | awk '{print $6}')
TX_DROPPED=$(netstat -i | grep eth0 | awk '{print $10}')
RX_ERRORS=$(netstat -i | grep eth0 | awk '{print $5}')
TX_ERRORS=$(netstat -i | grep eth0 | awk '{print $9}')

READ_OPS_ORADATA=$(iostat -k | grep "$ORADATA" | awk '{print $3}')
READ_OPS_ORAARCH=$(iostat -k | grep "$ORAARCH" | awk '{print $3}')
READ_OPS_ORATMP=$(iostat -k | grep "$ORATMP" | awk '{print $3}')
READ_OPS_ORAREDO=$(iostat -k | grep "$ORAREDO" | awk '{print $3}')
READ_OPS_ORACLE=$(iostat -k | grep "$ORACLE" | awk '{print $3}')
READ_OPS_NFSSHARE=$(iostat -k | grep "$NFSSHARE" | awk '{print $3}')
READ_OPS_ROOT=$(iostat -k | grep "$ROOT" | awk '{print $3}')

WRITE_OPS_ORADATA=$(iostat -k | grep "$ORADATA" | awk '{print $4}')
WRITE_OPS_ORAARCH=$(iostat -k | grep "$ORAARCH" | awk '{print $4}')
WRITE_OPS_ORATMP=$(iostat -k | grep "$ORATMP" | awk '{print $4}')
WRITE_OPS_ORAREDO=$(iostat -k | grep "$ORAREDO" | awk '{print $4}')
WRITE_OPS_ORACLE=$(iostat -k | grep "$ORACLE" | awk '{print $4}')
WRITE_OPS_NFSSHARE=$(iostat -k | grep "$NFSSHARE" | awk '{print $4}')
WRITE_OPS_ROOT=$(iostat -k | grep "$ROOT" | awk '{print $4}')

SWAP_FREE=$(cat /proc/meminfo | grep "SwapFree" | awk '{print $2}')
SWAP_TOTAL=$(cat /proc/meminfo | grep "SwapTotal" | awk '{print $2}')
SWAP_USED=$(echo "$SWAP_TOTAL - $SWAP_FREE" | bc )
SWAP_USED_PERCENTAGE=$(echo "scale=5;($SWAP_USED/$SWAP_TOTAL)*100" | bc )


#  SEND MEMORY USAGE
/usr/local/bin/aws cloudwatch put-metric-data                                               \
--metric-name mem_used_percent                                                              \
--namespace "$CLOUDWATCH_NAMESPACE"                                                         \
--dimensions ImageId="$IMAGE_ID",InstanceId="$INSTANCE_ID",InstanceType="$INSTANCE_TYPE"    \
--value "$MEMORY_USAGE"                                                                     \
--unit Percent

#  SEND DISK USAGE ORADATA
/usr/local/bin/aws cloudwatch put-metric-data                                                                                                                                                   \
--metric-name disk_used_percent_oradata                                                                                                                                                         \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                                                                                             \
--dimensions path="$REMOTE_VOLUME_PATH_ORADATA",InstanceId="$INSTANCE_ID",ImageId="$IMAGE_ID",InstanceType="$INSTANCE_TYPE",device="$REMOTE_VOLUME_DEV_ORADATA",fstype="$REMOTE_VOLUME_FSTYPE"  \
--value "$DISK_USAGE_ORADATA"                                                                                                                                                                   \
--unit Percent

#  SEND DISK USAGE ORAARCH
/usr/local/bin/aws cloudwatch put-metric-data                                                                                                                                                   \
--metric-name disk_used_percent_oraarch                                                                                                                                                         \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                                                                                             \
--dimensions path="$REMOTE_VOLUME_PATH_ORAARCH",InstanceId="$INSTANCE_ID",ImageId="$IMAGE_ID",InstanceType="$INSTANCE_TYPE",device="$REMOTE_VOLUME_DEV_ORAARCH",fstype="$REMOTE_VOLUME_FSTYPE"  \
--value "$DISK_USAGE_ORAARCH"                                                                                                                                                                   \
--unit Percent

#  SEND DISK USAGE ORATMP
/usr/local/bin/aws cloudwatch put-metric-data                                                                                                                                                   \
--metric-name disk_used_percent_oratmp                                                                                                                                                          \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                                                                                             \
--dimensions path="$REMOTE_VOLUME_PATH_ORATMP",InstanceId="$INSTANCE_ID",ImageId="$IMAGE_ID",InstanceType="$INSTANCE_TYPE",device="$REMOTE_VOLUME_DEV_ORATMP",fstype="$REMOTE_VOLUME_FSTYPE"    \
--value "$DISK_USAGE_ORATMP"                                                                                                                                                                    \
--unit Percent

#  SEND DISK USAGE ORAREDO
/usr/local/bin/aws cloudwatch put-metric-data                                                                                                                                                   \
--metric-name disk_used_percent_oraredo                                                                                                                                                         \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                                                                                             \
--dimensions path="$REMOTE_VOLUME_PATH_ORAREDO",InstanceId="$INSTANCE_ID",ImageId="$IMAGE_ID",InstanceType="$INSTANCE_TYPE",device="$REMOTE_VOLUME_DEV_ORAREDO",fstype="$REMOTE_VOLUME_FSTYPE"  \
--value "$DISK_USAGE_ORAREDO"                                                                                                                                                                   \
--unit Percent

#  SEND DISK USAGE ORACLE
/usr/local/bin/aws cloudwatch put-metric-data                                                                                                                                                   \
--metric-name disk_used_percent_oracle                                                                                                                                                          \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                                                                                             \
--dimensions path="$REMOTE_VOLUME_PATH_ORACLE",InstanceId="$INSTANCE_ID",ImageId="$IMAGE_ID",InstanceType="$INSTANCE_TYPE",device="$REMOTE_VOLUME_DEV_ORACLE",fstype="$REMOTE_VOLUME_FSTYPE"    \
--value "$DISK_USAGE_ORACLE"                                                                                                                                                                    \
--unit Percent

#  SEND DISK USAGE ROOT
/usr/local/bin/aws cloudwatch put-metric-data                                                                                                                                                   \
--metric-name disk_used_percent_root                                                                                                                                                            \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                                                                                             \
--dimensions path="$REMOTE_VOLUME_PATH_ROOT",InstanceId="$INSTANCE_ID",ImageId="$IMAGE_ID",InstanceType="$INSTANCE_TYPE",device="$REMOTE_VOLUME_DEV_ROOT",fstype="$REMOTE_VOLUME_FSTYPE"        \
--value "$DISK_USAGE_ROOT"                                                                                                                                                                    \
--unit Percent

#  SEND VOLUME READS ORADATA
/usr/local/bin/aws cloudwatch put-metric-data                                                                                                                                                   \
--metric-name volume_reads_oradata                                                                                                                                                              \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                                                                                             \
--dimensions path="$REMOTE_VOLUME_PATH_ORADATA",InstanceId="$INSTANCE_ID",ImageId="$IMAGE_ID",InstanceType="$INSTANCE_TYPE",device="$REMOTE_VOLUME_DEV_ORADATA",fstype="$REMOTE_VOLUME_FSTYPE"  \
--value "$READ_OPS_ORADATA"                                                                                                                                                                     \
--unit Kilobytes/Second

#  SEND VOLUME READS ORAARCH
/usr/local/bin/aws cloudwatch put-metric-data                                                                                                                                                   \
--metric-name volume_reads_oraarch                                                                                                                                                              \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                                                                                             \
--dimensions path="$REMOTE_VOLUME_PATH_ORAARCH",InstanceId="$INSTANCE_ID",ImageId="$IMAGE_ID",InstanceType="$INSTANCE_TYPE",device="$REMOTE_VOLUME_DEV_ORAARCH",fstype="$REMOTE_VOLUME_FSTYPE"  \
--value "$READ_OPS_ORAARCH"                                                                                                                                                                     \
--unit Kilobytes/Second

#  SEND VOLUME READS ORATMP
/usr/local/bin/aws cloudwatch put-metric-data                                                                                                                                                   \
--metric-name volume_reads_oratmp                                                                                                                                                               \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                                                                                             \
--dimensions path="$REMOTE_VOLUME_PATH_ORATMP",InstanceId="$INSTANCE_ID",ImageId="$IMAGE_ID",InstanceType="$INSTANCE_TYPE",device="$REMOTE_VOLUME_DEV_ORATMP",fstype="$REMOTE_VOLUME_FSTYPE"    \
--value "$READ_OPS_ORATMP"                                                                                                                                                                      \
--unit Kilobytes/Second

#  SEND VOLUME READS ORAREDO
/usr/local/bin/aws cloudwatch put-metric-data                                                                                                                                                   \
--metric-name volume_reads_oraredo                                                                                                                                                              \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                                                                                             \
--dimensions path="$REMOTE_VOLUME_PATH_ORAREDO",InstanceId="$INSTANCE_ID",ImageId="$IMAGE_ID",InstanceType="$INSTANCE_TYPE",device="$REMOTE_VOLUME_DEV_ORAREDO",fstype="$REMOTE_VOLUME_FSTYPE"  \
--value "$READ_OPS_ORAREDO"                                                                                                                                                                     \
--unit Kilobytes/Second

#  SEND VOLUME READS ORACLE
/usr/local/bin/aws cloudwatch put-metric-data                                                                                                                                                   \
--metric-name volume_reads_oracle                                                                                                                                                               \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                                                                                             \
--dimensions path="$REMOTE_VOLUME_PATH_ORACLE",InstanceId="$INSTANCE_ID",ImageId="$IMAGE_ID",InstanceType="$INSTANCE_TYPE",device="$REMOTE_VOLUME_DEV_ORACLE",fstype="$REMOTE_VOLUME_FSTYPE"    \
--value "$READ_OPS_ORACLE"                                                                                                                                                                      \
--unit Kilobytes/Second

#  SEND VOLUME READS NFSSHARE
/usr/local/bin/aws cloudwatch put-metric-data                                                                                                                                                   \
--metric-name volume_reads_nfsshare                                                                                                                                                               \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                                                                                             \
--dimensions path="$REMOTE_VOLUME_PATH_NFSSHARE",InstanceId="$INSTANCE_ID",ImageId="$IMAGE_ID",InstanceType="$INSTANCE_TYPE",device="$REMOTE_VOLUME_DEV_NFSSHARE",fstype="$REMOTE_VOLUME_FSTYPE"    \
--value "$READ_OPS_NFSSHARE"                                                                                                                                                                      \
--unit Kilobytes/Second

#  SEND VOLUME READS ROOT
/usr/local/bin/aws cloudwatch put-metric-data                                                                                                                                                   \
--metric-name volume_reads_root                                                                                                                                                                 \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                                                                                             \
--dimensions path="$REMOTE_VOLUME_PATH_ROOT",InstanceId="$INSTANCE_ID",ImageId="$IMAGE_ID",InstanceType="$INSTANCE_TYPE",device="$REMOTE_VOLUME_DEV_ROOT",fstype="$REMOTE_VOLUME_FSTYPE"        \
--value "$READ_OPS_ROOT"                                                                                                                                                                        \
--unit Kilobytes/Second

#  SEND VOLUME WRITES ORADATA
/usr/local/bin/aws cloudwatch put-metric-data                                                                                                                                                   \
--metric-name volume_writes_oradata                                                                                                                                                             \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                                                                                             \
--dimensions path="$REMOTE_VOLUME_PATH_ORADATA",InstanceId="$INSTANCE_ID",ImageId="$IMAGE_ID",InstanceType="$INSTANCE_TYPE",device="$REMOTE_VOLUME_DEV_ORADATA",fstype="$REMOTE_VOLUME_FSTYPE"  \
--value "$WRITE_OPS_ORADATA"                                                                                                                                                                    \
--unit Kilobytes/Second

#  SEND VOLUME WRITES ORAARCH
/usr/local/bin/aws cloudwatch put-metric-data                                                                                                                                                   \
--metric-name volume_writes_oraarch                                                                                                                                                             \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                                                                                             \
--dimensions path="$REMOTE_VOLUME_PATH_ORAARCH",InstanceId="$INSTANCE_ID",ImageId="$IMAGE_ID",InstanceType="$INSTANCE_TYPE",device="$REMOTE_VOLUME_DEV_ORAARCH",fstype="$REMOTE_VOLUME_FSTYPE"  \
--value "$WRITE_OPS_ORAARCH"                                                                                                                                                                    \
--unit Kilobytes/Second

#  SEND VOLUME WRITES ORATMP
/usr/local/bin/aws cloudwatch put-metric-data                                                                                                                                                   \
--metric-name volume_writes_oratmp                                                                                                                                                              \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                                                                                             \
--dimensions path="$REMOTE_VOLUME_PATH_ORATMP",InstanceId="$INSTANCE_ID",ImageId="$IMAGE_ID",InstanceType="$INSTANCE_TYPE",device="$REMOTE_VOLUME_DEV_ORATMP",fstype="$REMOTE_VOLUME_FSTYPE"    \
--value "$WRITE_OPS_ORATMP"                                                                                                                                                                     \
--unit Kilobytes/Second

#  SEND VOLUME WRITES ORAREDO
/usr/local/bin/aws cloudwatch put-metric-data                                                                                                                                                   \
--metric-name volume_writes_oraredo                                                                                                                                                             \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                                                                                             \
--dimensions path="$REMOTE_VOLUME_PATH_ORAREDO",InstanceId="$INSTANCE_ID",ImageId="$IMAGE_ID",InstanceType="$INSTANCE_TYPE",device="$REMOTE_VOLUME_DEV_ORAREDO",fstype="$REMOTE_VOLUME_FSTYPE"  \
--value "$WRITE_OPS_ORAREDO"                                                                                                                                                                    \
--unit Kilobytes/Second

#  SEND VOLUME WRITES ORACLE
/usr/local/bin/aws cloudwatch put-metric-data                                                                                                                                                   \
--metric-name volume_writes_oracle                                                                                                                                                              \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                                                                                             \
--dimensions path="$REMOTE_VOLUME_PATH_ORACLE",InstanceId="$INSTANCE_ID",ImageId="$IMAGE_ID",InstanceType="$INSTANCE_TYPE",device="$REMOTE_VOLUME_DEV_ORACLE",fstype="$REMOTE_VOLUME_FSTYPE"    \
--value "$WRITE_OPS_ORACLE"                                                                                                                                                                     \
--unit Kilobytes/Second                                                                                                                                                                         \
#  SEND VOLUME WRITES NFSSHARE
/usr/local/bin/aws cloudwatch put-metric-data                                                                                                                                                   \
--metric-name volume_writes_nfsshare                                                                                                                                                              \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                                                                                             \
--dimensions path="$REMOTE_VOLUME_PATH_NFSSHARE",InstanceId="$INSTANCE_ID",ImageId="$IMAGE_ID",InstanceType="$INSTANCE_TYPE",device="$REMOTE_VOLUME_DEV_NFSSHARE",fstype="$REMOTE_VOLUME_FSTYPE"    \
--value "$WRITE_OPS_NFSSHARE"                                                                                                                                                                     \
--unit Kilobytes/Second                                                                                                                                                                         \

#  SEND VOLUME WRITES ROOT
/usr/local/bin/aws cloudwatch put-metric-data                                                                                                                                                   \
--metric-name volume_writes_root                                                                                                                                                                \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                                                                                             \
--dimensions path="$REMOTE_VOLUME_PATH_ROOT",InstanceId="$INSTANCE_ID",ImageId="$IMAGE_ID",InstanceType="$INSTANCE_TYPE",device="$REMOTE_VOLUME_DEV_ROOT",fstype="$REMOTE_VOLUME_FSTYPE"        \
--value "$WRITE_OPS_ROOT"                                                                                                                                                                       \
--unit Kilobytes/Second

#  SEND Rx DROPPED PACKETS
/usr/local/bin/aws cloudwatch put-metric-data                                                                       \
--metric-name net_drop_in                                                                                           \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                 \
--dimensions  InstanceId="$INSTANCE_ID",ImageId="$IMAGE_ID",InstanceType="$INSTANCE_TYPE",interface="$INSTANCE_NIC" \
--value "$RX_DROPPED"                                                                                               \
--unit Count

#  SEND Tx DROPPED PACKETS
/usr/local/bin/aws cloudwatch put-metric-data                                                                       \
--metric-name net_drop_out                                                                                          \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                 \
--dimensions  InstanceId="$INSTANCE_ID",ImageId="$IMAGE_ID",InstanceType="$INSTANCE_TYPE",interface="$INSTANCE_NIC" \
--value "$TX_DROPPED"                                                                                               \
--unit Count

#  SEND Rx ERRORS
/usr/local/bin/aws cloudwatch put-metric-data                                                                       \
--metric-name net_err_in                                                                                            \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                 \
--dimensions  InstanceId="$INSTANCE_ID",ImageId="$IMAGE_ID",InstanceType="$INSTANCE_TYPE",interface="$INSTANCE_NIC" \
--value "$RX_ERRORS"                                                                                                \
--unit Count

#  SEND Tx ERRORS
/usr/local/bin/aws cloudwatch put-metric-data                                                                       \
--metric-name net_err_out                                                                                           \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                 \
--dimensions  InstanceId="$INSTANCE_ID",ImageId="$IMAGE_ID",InstanceType="$INSTANCE_TYPE",interface="$INSTANCE_NIC" \
--value "$TX_ERRORS"                                                                                                \
--unit Count

#  SEND SWAP USED
/usr/local/bin/aws cloudwatch put-metric-data                                                                       \
--metric-name swap_used_percentage                                                                                         \
--namespace "$CLOUDWATCH_NAMESPACE"                                                                                 \
--dimensions  InstanceId="$INSTANCE_ID" \
--value "$SWAP_USED_PERCENTAGE"                                                                                                \
--unit Count

exit 0
