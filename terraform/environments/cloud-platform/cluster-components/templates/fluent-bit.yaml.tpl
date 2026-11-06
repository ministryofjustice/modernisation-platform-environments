image:
  repository: fluent/fluent-bit
  ## Temporarily overriding default tag as latest helm chart release is yet to have the latest fluent-bit as the default
  ## Remove tag in next helm bump to revert tag management back to helm default
  tag: 4.2.0
  pullPolicy: Always
serviceMonitor:
  enabled: true
  interval: 10s
  scrapeTimeout: 10s

serviceAccount:
  create: false
  name: fluent-bit-cp-managed

tolerations:
  - key: node-role.kubernetes.io/master
    effect: NoSchedule
  - key: "monitoring-node"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
  - key: "ingress-node"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"

securityContext:
  capabilities:
    drop:
      - NET_RAW

luaScripts:
  cb_extract_team_values.lua: |
    function cb_extract_team_values(tag, timestamp, record)
      local new_record = record

      if record["kubernetes"]["annotations"] == nil then
        new_record["kubernetes"]["annotations"] = {}
        new_record["kubernetes"]["annotations"]["github_teams"] = "all-org-members"
        new_record["github_teams"] = "all-org-members"

        return 1, timestamp, new_record
      end

      if record["kubernetes"]["annotations"]["github_teams"] == nil or record["kubernetes"]["annotations"]["github_teams"] == '' then
        new_record["kubernetes"]["annotations"]["github_teams"] = "all-org-members"
        new_record["github_teams"] = "all-org-members"

        return 1, timestamp, new_record
      end

      local github_team = string.gmatch(record["kubernetes"]["annotations"]["github_teams"], "[^_]+")

      local team_matches = {}

      for team in github_team do
        table.insert(team_matches, team)
      end

      if #team_matches > 0 then
        new_record["github_teams"] = team_matches
        return 1, timestamp, new_record
      else
        return 0, timestamp, record
      end
    end
  
  # Filter to remove external-dns warnings about disallowed rune U+002A. It can be removed after we have upgraded to external-dns v0.19.0 or later.
  # https://github.com/kubernetes-sigs/external-dns/issues/5581
  cb_filter_external_dns_warnings.lua: |
    function cb_filter_external_dns_warnings(tag, timestamp, record)
        if record["kubernetes"] == nil then
            return 1, timestamp, record
        end

        if record["kubernetes"]["container_name"] ~= "external-dns" then
            return 1, timestamp, record
        end

        local log = record["log"]
        if log == nil then
            return 1, timestamp, record
        end

        if string.find(log, "disallowed rune", 1, true) then
            return -1, timestamp, record
        end

        return 1, timestamp, record
    end

## https://docs.fluentbit.io/manual/administration/configuring-fluent-bit/configuration-file
config:
  service: |
    [SERVICE]
        Flush                             1
        Log_Level                         info
        Daemon                            Off
        Grace                             30
        Parsers_File                      parsers.conf
        Parsers_File                      custom_parsers.conf
        HTTP_Server                       On
        HTTP_Listen                       0.0.0.0
        HTTP_Port                         2020
        Storage.path                      /var/log/flb-storage/
        Storage.max_chunks_up             256 # maximum number of Chunks that can be up in memory. This helps to control memory usage.
        Storage.backlog.mem_limit         2GB # maximum value of memory to use when processing data chunks that were not delivered and are still in the storage layer

  inputs: |
    [INPUT]
        Name                              tail
        Alias                             user_app_data
        Tag                               kubernetes.*
        Path                              /var/log/containers/*.log
        Exclude_Path                      *nginx-ingress*.log,eventrouter-*.log
        Parser                            cri-containerd
        Multiline.parser                  docker, cri
        Refresh_Interval                  5
        Skip_Long_Lines                   On
        Buffer_Max_Size                   2MB # limit of the buffer size per monitored file. When a buffer needs to be increased (e.g: very long lines), this value is used to restrict how much the memory buffer can grow. If reading a file exceeds this limit, the file is removed from the monitored file list.
        Buffer_Chunk_Size                 2MB
        Offset_Key                        pause_position_kubernetes
        DB                                kubernetes.db
        DB.locking                        true
        ## https://docs.fluentbit.io/manual/administration/buffering-and-storage#filesystem-buffering-to-the-rescue
        Storage.type                      filesystem
        ## https://docs.fluentbit.io/manual/administration/backpressure#storage.max_chunks_up
        Storage.pause_on_chunks_overlimit Off
        Threaded                          True

    [INPUT]
        Name                              tail
        Alias                             default_nginx_ingress
        Tag                               nginx-ingress.*
        Path                              /var/log/containers/nginx-ingress-default*controller*_ingress-controllers_*.log
        Exclude_Path                      /var/log/containers/*nginx-ingress-modsec*controller*_ingress-controllers_*.log
        Parser                            cri-containerd
        Refresh_Interval                  1
        Skip_Long_Lines                   On
        Buffer_Max_Size                   20MB
        Buffer_Chunk_Size                 256KB
        Rotate_Wait                       10
        Offset_Key                        pause_position_nginx_ingress
        DB                                nginx-ingress.db
        DB.locking                        true
        Storage.type                      filesystem
        Storage.pause_on_chunks_overlimit Off
        Threaded                          True

    [INPUT]
        Name                              tail
        Alias                             internal_nginx_ingress
        Tag                               nginx-ingress.*
        Path                              /var/log/containers/nginx-ingress-internal*controller*_ingress-controllers_*.log
        Exclude_Path                      /var/log/containers/*nginx-ingress-modsec*controller*_ingress-controllers_*.log
        Parser                            cri-containerd
        Refresh_Interval                  1
        Skip_Long_Lines                   On
        Buffer_Max_Size                   20MB
        Buffer_Chunk_Size                 256KB
        Rotate_Wait                       10
        Offset_Key                        pause_position_nginx_ingress
        DB                                nginx-ingress.db
        DB.locking                        true
        Storage.type                      filesystem
        Storage.pause_on_chunks_overlimit Off
        Threaded                          True

    [INPUT]
        Name                              kubernetes_events
        Alias                             eventrouter
        Tag                               eventrouter.*
        DB                                eventrouter.db
        # ask k8s API for updates every x seconds
        interval_sec                      60
        # fetch at most x items per requests (pagination)
        kube_request_limit                250
        Storage.type                      filesystem
        Storage.pause_on_chunks_overlimit True

    [INPUT]
        Name                              tail
        Alias                             kube_apiserver_audit
        Tag                               kube-apiserver-audit.*
        Path                              /var/log/kube-apiserver-audit.log
        Parser                            cri-containerd
        Refresh_Interval                  5
        Buffer_Max_Size                   5MB
        Buffer_Chunk_Size                 1M
        Offset_Key                        pause_position_api
        DB                                kube-apiserver-audit.db
        DB.locking                        true
        Storage.type                      filesystem
        Storage.pause_on_chunks_overlimit True

    [INPUT]
        Name                              tail
        Alias                             ipamd
        Tag                               ipamd.*
        Path                              /var/log/aws-routed-eni/ipamd.log
        Parser                            cri-containerd
        Refresh_Interval                  5
        Buffer_Max_Size                   5MB
        Buffer_Chunk_Size                 1M
        Offset_Key                        pause_position_ipamd
        DB                                ipamd.db
        DB.locking                        true
        Storage.type                      filesystem
        Storage.pause_on_chunks_overlimit True          

  filters: |
    [FILTER]
        Name                              kubernetes
        Alias                             user_app_data
        Match                             kubernetes.*
        Kube_Tag_Prefix                   kubernetes.var.log.containers.
        Kube_URL                          https://kubernetes.default.svc:443
        Kube_CA_File                      /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        Kube_Token_File                   /var/run/secrets/kubernetes.io/serviceaccount/token
        K8S-Logging.Parser                On
        K8S-Logging.Exclude               On
        Merge_Log                         Off
        Buffer_Size                       1MB

    [FILTER]
        Name                              lua
        Alias                             user_app_data_os
        Match                             kubernetes.*
        script                            /fluent-bit/scripts/cb_extract_team_values.lua
        call                              cb_extract_team_values

    [FILTER]
        Name                              lua
        Alias                             external_dns_warnings_filter
        Match                             kubernetes.*
        script                            /fluent-bit/scripts/cb_filter_external_dns_warnings.lua
        call                              cb_filter_external_dns_warnings

    [FILTER]
        Name                              kubernetes
        Alias                             default_nginx_ingress
        Match                             nginx-ingress.*
        Kube_Tag_Prefix                   nginx-ingress.var.log.containers.
        Kube_URL                          https://kubernetes.default.svc:443
        Kube_CA_File                      /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        Kube_Token_File                   /var/run/secrets/kubernetes.io/serviceaccount/token
        K8S-Logging.Parser                On
        K8S-Logging.Exclude               On
        Keep_Log                          Off
        Merge_Log                         On
        Merge_Log_Key                     log_processed
        Buffer_Size                       1MB

  outputs: |
    [OUTPUT]
        Name                              opensearch
        Alias                             user_app_data_os
        Match                             kubernetes.*

        Port                              443
        Type                              _doc
        Time_Key                          @timestamp
        Current_Time_Index                On
        Logstash_Prefix                   ${cluster}_kubernetes_cluster
        tls                               On
        Logstash_Format                   On
        Replace_Dots                      On
        Generate_ID                       On
        Retry_Limit                       False
        AWS_AUTH                          On
        AWS_REGION                        eu-west-2
        Suppress_Type_Name                On
        Buffer_Size                       False

    [OUTPUT]
        Name                              opensearch
        Alias                             default_nginx_ingress_os
        Match                             nginx-ingress.*
        
        Port                              443
        Type                              _doc
        Time_Key                          @timestamp
        Current_Time_Index                On
        Logstash_Prefix                   ${cluster}_kubernetes_ingress
        tls                               On
        Logstash_Format                   On
        Replace_Dots                      On
        Generate_ID                       On
        Retry_Limit                       10
        AWS_AUTH                          On
        AWS_REGION                        eu-west-2
        Suppress_Type_Name                On
        Buffer_Size                       False

    [OUTPUT]
        Name                              opensearch
        Alias                             eventrouter_os
        Match                             eventrouter.*
        
        Port                              443
        Type                              _doc
        Time_Key                          @timestamp
        Current_Time_Index                On
        Logstash_Prefix                   ${cluster}_eventrouter
        tls                               On
        Logstash_Format                   On
        Replace_Dots                      On
        Generate_ID                       On
        Retry_Limit                       False
        AWS_AUTH                          On
        AWS_REGION                        eu-west-2
        Suppress_Type_Name                On
        Buffer_Size                       False

    [OUTPUT]
        Name                              opensearch
        Alias                             ipamd_os
        Match                             ipamd.*
        
        Port                              443
        Type                              _doc
        Time_Key                          @timestamp
        Current_Time_Index                On
        Logstash_Prefix                   ${cluster}_ipamd
        tls                               On
        Logstash_Format                   On
        Replace_Dots                      On
        Generate_ID                       On
        Retry_Limit                       False
        AWS_AUTH                          On
        AWS_REGION                        eu-west-2
        Suppress_Type_Name                On
        Buffer_Size                       False

    [OUTPUT]
        Name                              s3
        Alias                             user_app_data_s3
        Match                             kubernetes.*
        bucket                            ${s3_bucket_application_logs}
        region                            eu-west-2
        total_file_size                   5M
        upload_timeout                    10m
        store_dir                         /tmp/fluent-bit/s3
        store_dir_limit_size              1G
        s3_key_format                     /logs/%Y/%m/%d/%H/%M/%S-$UUID
        use_put_object                    true
        Retry_Limit                       False            

  ## https://docs.fluentbit.io/manual/pipeline/parsers
  customParsers: |
    [PARSER]
        Name         generic-json
        Format       json
        Time_Key     time
        Time_Format %Y-%m-%dT%H:%M:%S.%L%z
        Time_Keep    On
    # CRI-containerd Parser
    [PARSER]
        # https://rubular.com/r/DjPmoX5HnQMesk
        Name cri-containerd
        Format regex
        Regex ^(?<time>[^ ]+) (?<stream>stdout|stderr) (?<logtag>[^ ]*) (?<log>.*)$
        Time_Key    time
        Time_Format %Y-%m-%dT%H:%M:%S.%L%z

priorityClassName: system-cluster-critical
