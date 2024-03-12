#!/bin/bash -xe
# send script output to /tmp so we can debug boot failures
# Output all log
exec > >(tee /tmp/userdata.log|logger -t user-data-extra -s 2>/dev/console) 2>&1

echo "assumeyes=1" >> /etc/yum.conf

# Update all packages
sudo yum -y update

# Setup YUM install Utils
#sudo yum -y install curl wget unzip jq


# Install AWS CLI Libs
echo "Seup AWSCLI V2....."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Substituted in from terraform template
RISING_WAVE_NODE_TYPE=${RISING_WAVE_NODE_TYPE}
echo "RISING_WAVE_NODE_TYPE: $RISING_WAVE_NODE_TYPE"
echo

# Part of temporary noddy service discovery
if [ "$RISING_WAVE_NODE_TYPE" = "meta" ]; then
  aws s3 rm s3://dpr-working-development/rising-wave/hosts/risingwave_meta.txt
  # Sleep gives us a bit of time for the meta node and etcd hosts files to be gone by the time we start setup
  sleep 60
fi

if grep ssm-user /etc/passwd &> /dev/null;
then
  echo "ssm-user already exists - skipping create"
else
  # Create the ssm-user using system defaults.
  # See /etc/default/useradd
  echo "ssm-user does not exist - creating"
  sudo useradd ssm-user --create-home
  echo "ssm-user created"

  # TODO: Remove temporary NOPASSWD used for dev
  cd /etc/sudoers.d
  echo "ssm-user ALL=(ALL) NOPASSWD:ALL" > ssm-agent-users
fi

RISING_WAVE_HOME=/opt/risingwave

sudo mkdir -p "$RISING_WAVE_HOME"
cd "$RISING_WAVE_HOME"

if [ -z "$ARCH" ]; then
  ARCH=$(uname -m)
fi

VERSION="v1.7.0-standalone"
BASE_URL="https://github.com/risingwavelabs/risingwave/releases/download"

if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
  BASE_ARCHIVE_NAME="risingwave-$VERSION-x86_64-unknown-linux-all-in-one"
  ARCHIVE_NAME="$BASE_ARCHIVE_NAME.tar.gz"
  URL="$BASE_URL/$VERSION/$ARCHIVE_NAME"
elif [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
  BASE_ARCHIVE_NAME="risingwave-$VERSION-aarch64-unknown-linux-all-in-one"
  ARCHIVE_NAME="$BASE_ARCHIVE_NAME.tar.gz"
  URL="$BASE_URL/$VERSION/$ARCHIVE_NAME"
fi

############# BINARY INSTALL
echo
echo "Downloading RisingWave@$VERSION from $URL into $PWD."
echo
sudo curl -L "$URL" -o "$ARCHIVE_NAME"
sudo tar -xzf "$ARCHIVE_NAME"
sudo chmod +x risingwave
sudo rm "$ARCHIVE_NAME"
echo
echo "Successfully installed RisingWave@$VERSION binary."
echo

config_file_contents=`cat << EOF
[server]
heartbeat_interval_ms = 1000
connection_pool_size = 16
metrics_level = "Info"
telemetry_enabled = false
grpc_max_reset_stream = 200

[server.heap_profiling]
enable_auto = true
threshold_auto = 0.8999999761581421
dir = "./"

[meta]
min_sst_retention_time_sec = 86400
full_gc_interval_sec = 86400
collect_gc_watermark_spin_interval_sec = 5
periodic_compaction_interval_sec = 60
vacuum_interval_sec = 30
vacuum_spin_interval_ms = 10
hummock_version_checkpoint_interval_sec = 30
enable_hummock_data_archive = false
min_delta_log_num_for_hummock_version_checkpoint = 10
max_heartbeat_interval_secs = 300
disable_recovery = false
disable_automatic_parallelism_control = false
meta_leader_lease_secs = 30
default_parallelism = "Full"
enable_compaction_deterministic = false
enable_committed_sst_sanity_check = false
node_num_monitor_interval_sec = 10
backend = "Mem"
periodic_space_reclaim_compaction_interval_sec = 3600
periodic_ttl_reclaim_compaction_interval_sec = 1800
periodic_tombstone_reclaim_compaction_interval_sec = 600
periodic_split_compact_group_interval_sec = 10
move_table_size_limit = 10737418240
split_group_size_limit = 68719476736
cut_table_size_limit = 1073741824
do_not_config_object_storage_lifecycle = false
partition_vnode_count = 16
table_write_throughput_threshold = 16777216
min_table_split_write_throughput = 4194304
compaction_task_max_heartbeat_interval_secs = 30
compaction_task_max_progress_interval_secs = 600
hybird_partition_vnode_count = 4
event_log_enabled = true
event_log_channel_max_size = 10

[meta.compaction_config]
max_bytes_for_level_base = 536870912
max_bytes_for_level_multiplier = 5
max_compaction_bytes = 2147483648
sub_level_max_compaction_bytes = 134217728
level0_tier_compact_file_number = 12
target_file_size_base = 33554432
compaction_filter_mask = 6
max_sub_compaction = 4
level0_stop_write_threshold_sub_level_number = 300
level0_sub_level_compact_level_count = 3
level0_overlapping_sub_level_compact_level_count = 12
max_space_reclaim_bytes = 536870912
level0_max_compact_file_number = 100
tombstone_reclaim_ratio = 40
enable_emergency_picker = true

[meta.developer]
meta_cached_traces_num = 256
meta_cached_traces_memory_limit_bytes = 134217728
meta_enable_trivial_move = true
meta_enable_check_task_level_overlap = false

[batch]
enable_barrier_read = false
statement_timeout_in_sec = 3600
frontend_compute_runtime_worker_threads = 4

[batch.developer]
batch_connector_message_buffer_size = 16
batch_output_channel_size = 64
batch_chunk_size = 1024

[streaming]
in_flight_barrier_nums = 10000
async_stack_trace = "ReleaseVerbose"
unique_user_stream_errors = 10

[streaming.developer]
stream_enable_executor_row_count = false
stream_connector_message_buffer_size = 16
stream_unsafe_extreme_cache_size = 10
stream_chunk_size = 256
stream_exchange_initial_permits = 2048
stream_exchange_batched_permits = 256
stream_exchange_concurrent_barriers = 1
stream_exchange_concurrent_dispatchers = 0
stream_dml_channel_initial_permits = 32768
stream_hash_agg_max_dirty_groups_heap_size = 67108864

[storage]
share_buffers_sync_parallelism = 1
share_buffer_compaction_worker_threads_number = 4
shared_buffer_flush_ratio = 0.800000011920929
imm_merge_threshold = 0
write_conflict_detection_enabled = true
max_prefetch_block_number = 16
disable_remote_compactor = false
share_buffer_upload_concurrency = 8
compactor_max_task_multiplier = 2.5
compactor_memory_available_proportion = 0.8
sstable_id_remote_fetch_number = 10
min_sst_size_for_streaming_upload = 33554432
max_sub_compaction = 4
max_concurrent_compaction_task_number = 16
max_preload_wait_time_mill = 0
max_version_pinning_duration_sec = 10800
compactor_max_sst_key_count = 2097152
compact_iter_recreate_timeout_ms = 600000
compactor_max_sst_size = 536870912
enable_fast_compaction = false
check_compaction_result = false
max_preload_io_retry_times = 3
compactor_fast_max_compact_delete_ratio = 40
compactor_fast_max_compact_task_size = 2147483648
mem_table_spill_threshold = 4194304

[storage.data_file_cache]
dir = ""
capacity_mb = 1024
file_capacity_mb = 64
device_align = 4096
device_io_size = 16384
flushers = 4
reclaimers = 4
recover_concurrency = 8
lfu_window_to_cache_size_ratio = 1
lfu_tiny_lru_capacity_ratio = 0.01
insert_rate_limit_mb = 0
ring_buffer_capacity_mb = 256
catalog_bits = 6
compression = "none"

[storage.meta_file_cache]
dir = ""
capacity_mb = 1024
file_capacity_mb = 64
device_align = 4096
device_io_size = 16384
flushers = 4
reclaimers = 4
recover_concurrency = 8
lfu_window_to_cache_size_ratio = 1
lfu_tiny_lru_capacity_ratio = 0.01
insert_rate_limit_mb = 0
ring_buffer_capacity_mb = 256
catalog_bits = 6
compression = "none"

[storage.cache_refill]
data_refill_levels = []
timeout_ms = 6000
concurrency = 10
unit = 64
threshold = 0.5
recent_filter_layers = 6
recent_filter_rotate_interval_ms = 10000

[storage.object_store]
object_store_streaming_read_timeout_ms = 480000
object_store_streaming_upload_timeout_ms = 480000
object_store_upload_timeout_ms = 480000
object_store_read_timeout_ms = 480000

[storage.object_store.s3]
object_store_keepalive_ms = 600000
object_store_recv_buffer_size = 2097152
object_store_nodelay = true
object_store_req_retry_interval_ms = 20
object_store_req_retry_max_delay_ms = 10000
object_store_req_retry_max_attempts = 8
retry_unknown_service_error = false

[storage.object_store.s3.developer]
object_store_retry_unknown_service_error = false
object_store_retryable_service_error_codes = ["SlowDown", "TooManyRequests"]

[system]
barrier_interval_ms = 1000
checkpoint_frequency = 1
sstable_size_mb = 256
parallel_compact_size_mb = 512
block_size_kb = 64
bloom_false_positive = 0.001
max_concurrent_creating_streaming_jobs = 1
pause_on_next_bootstrap = false
enable_tracing = false

EOF`

echo "$config_file_contents" | sudo tee "$RISING_WAVE_HOME/risingwave.toml" > /dev/null


sudo groupadd -f risingwave
sudo useradd -d /opt/risingwave -s /bin/false -g risingwave risingwave
sudo chown -R risingwave:risingwave /opt/risingwave


HOST_NAME=$(hostname -s)

if [ "$RISING_WAVE_NODE_TYPE" = "meta" ]; then
    echo "Configuring Meta Node"
    echo "Started reading etcd host file from s3 at $(date)"
    # Temporary noddy service discovery for etcd
    timeout=300
    start_time=$(date +%s)
    while true; do
      aws s3 cp s3://dpr-working-development/rising-wave/hosts/risingwave_etcd.txt ./risingwave_etcd.txt
      if [ $? -eq 0 ]; then
        ETCD_HOST=$(cat ./risingwave_etcd.txt)
        if [ -z "$ETCD_HOST" ]; then
          echo "ETCD_HOST file empty"
        else
          echo "ETCD_HOST is $ETCD_HOST"
          rm -f ./risingwave_etcd.txt
          break
        fi
      else
        echo "Waiting for ETCD_HOST file"
      fi
      current_time=$(date +%s)
      elapsed_time=$((current_time - start_time))
      if [ $elapsed_time -ge $timeout ]; then
        echo "Failed to download etcd host file - reached timeout"
        exit 1
      fi
      sleep 10
    done
    meta_node_service_file_contents=`cat << EOF
[Unit]
Description=rising wave meta service

[Service]
User=risingwave
Type=simple
ExecStart=$RISING_WAVE_HOME/risingwave meta-node \\
 "--listen-addr" \\
 "0.0.0.0:5690" \\
 "--advertise-addr" \\
 "$HOST_NAME:5690" \\
 "--dashboard-host" \\
 "0.0.0.0:5691" \\
 "--backend" \\
 "etcd" \\
 "--etcd-endpoints" \\
 "$ETCD_HOST:2379" \\
 "--state-store" \\
 "hummock+s3://dpr-working-development" \\
 "--data-directory" \\
 "rising-wave/hummock/$HOST_NAME" \\
 "--config-path" \\
 "$RISING_WAVE_HOME/risingwave.toml"
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF`

  sudo systemctl daemon-reload
  sudo systemctl enable risingwave-meta
  sudo systemctl start risingwave-meta.service
  sudo systemctl status -l risingwave-meta.service

  echo "$meta_node_service_file_contents" | sudo tee /lib/systemd/system/risingwave-meta.service > /dev/null
  echo "$HOST_NAME" >risingwave_meta.txt
  aws s3 cp ./risingwave_meta.txt s3://dpr-working-development/rising-wave/hosts/risingwave_meta.txt
  echo "Wrote meta node host file to s3 at $(date)"
  rm -f ./risingwave_meta.txt

else
  # Temporary noddy service discovery for meta node
  # Write a file to S3 for now and rely on timings
  echo "Started reading meta node host file from s3 at $(date)"
  timeout=600
  start_time=$(date +%s)
  while true; do
    aws s3 cp s3://dpr-working-development/rising-wave/hosts/risingwave_meta.txt ./risingwave_meta.txt
    if [ $? -eq 0 ]; then
      META_NODE_HOST=$(cat ./risingwave_meta.txt)
      if [ -z "$META_NODE_HOST" ]; then
        echo "META_NODE_HOST file empty"
      else
        echo "META_NODE_HOST is $META_NODE_HOST"
        rm -f ./risingwave_meta.txt
        break
      fi
    else
      echo "Waiting for META_NODE_HOST file"
    fi
    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))
    if [ $elapsed_time -ge $timeout ]; then
      echo "Failed to download meta node host file - reached timeout"
      exit 1
    fi
    sleep 30
  done

  if [ "$RISING_WAVE_NODE_TYPE" = "compute" ]; then
    echo "Configuring Compute Node"
    compute_node_service_file_contents=`cat << EOF
[Unit]
Description=rising wave compute service

[Service]
User=risingwave
Type=simple
ExecStart=$RISING_WAVE_HOME/risingwave compute \\
 "--listen-addr" \\
 "0.0.0.0:5688" \\
 "--advertise-addr" \\
 "$HOST_NAME:5688" \\
 "--prometheus-listener-addr" \\
 "0.0.0.0:1222" \\
 "--meta-address" \\
 "http://$META_NODE_HOST:5690" \\
 "--metrics-level" \\
 "info" \\
 "--config-path" \\
 "$RISING_WAVE_HOME/risingwave.toml"
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF`

  echo "$compute_node_service_file_contents" | sudo tee /lib/systemd/system/risingwave-compute.service > /dev/null

  sudo systemctl daemon-reload
  sudo systemctl enable risingwave-compute
  sudo systemctl start risingwave-compute.service
  sudo systemctl status -l risingwave-compute.service

  elif [ "$RISING_WAVE_NODE_TYPE" = "compactor" ]; then
    echo "Configuring Compactor Node"
    compactor_node_service_file_contents=`cat << EOF
[Unit]
Description=rising wave compactor service

[Service]
User=risingwave
Type=simple
ExecStart=$RISING_WAVE_HOME/risingwave compactor \\
 "--listen-addr" \\
 "0.0.0.0:6660" \\
 "--advertise-addr" \\
 "$HOST_NAME:6660" \\
 "--prometheus-listener-addr" \\
 "0.0.0.0:1222" \\
 "--meta-address" \\
 "http://$META_NODE_HOST:5690" \\
 "--config-path" \\
 "$RISING_WAVE_HOME/risingwave.toml"
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF`

    echo "$compactor_node_service_file_contents" | sudo tee /lib/systemd/system/risingwave-compactor.service > /dev/null

    sudo systemctl daemon-reload
    sudo systemctl enable risingwave-compactor
    sudo systemctl start risingwave-compactor.service
    sudo systemctl status -l risingwave-compactor.service

  elif [ "$RISING_WAVE_NODE_TYPE" = "frontend" ]; then

  # Frontend node
    echo "Configuring Frontend Node"
    frontend_node_service_file_contents=`cat << EOF
[Unit]
Description=rising wave frontend service

[Service]
User=risingwave
Type=simple
ExecStart=$RISING_WAVE_HOME/risingwave frontend \\
 "--listen-addr" \\
 "0.0.0.0:4566" \\
 "--advertise-addr" \\
 "$HOST_NAME:4566" \\
 "--prometheus-listener-addr" \\
 "0.0.0.0:1222" \\
 "--meta-addr" \\
 "http://$META_NODE_HOST:5690" \\
 "--config-path" \\
 "$RISING_WAVE_HOME/risingwave.toml"
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF`

    echo "$frontend_node_service_file_contents" | sudo tee /lib/systemd/system/risingwave-frontend.service > /dev/null

    sudo systemctl daemon-reload
    sudo systemctl enable risingwave-frontend
    sudo systemctl start risingwave-frontend.service
    sudo systemctl status -l risingwave-frontend.service

  else
    echo "$RISING_WAVE_NODE_TYPE is not a valid rising wave node type"
    exit 1
  fi
fi


