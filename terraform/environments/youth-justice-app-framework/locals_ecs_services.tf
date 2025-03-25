locals {
  ecs_services = {
    auth = {
      name                              = "auth"
      image                             = "673920839910.dkr.ecr.eu-west-2.amazonaws.com/yjaf/auth:preprod"
      task_cpu                          = 1280
      container_cpu                     = 1024
      task_memory                       = 2560
      container_memory                  = 2048
      health_check_grace_period_seconds = 300
      additional_environment_variables = [
        {
          "name" : "GATEWAY_SERVICE_URI"
          "value" : "gateway.yjaf:8080"
        },
        {
          "name" : "JAVA_OPTS",
          "value" : "-Xmx1024m -Xms512m --add-modules java.se --add-exports java.base/jdk.internal.ref=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.nio=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.management/sun.management=ALL-UNNAMED --add-opens jdk.management/com.sun.management.internal=ALL-UNNAMED -Ddd.jmxfetch.enabled=true -Ddd.profiling.enabled=true -XX:FlightRecorderOptions=stackdepth=256 -Ddd.logs.injection=true -Ddd.trace.sample.rate=1 -Ddd.service=auth"
        }
      ]
      enable_postgres_secret = false
      additional_mount_points = [
        {
          sourceVolume : "hosts",
          containerPath : "/etc",
          readOnly : false
        }
      ]
      volumes = [
        {
          "name" : "hosts",
          "host" : {}
        }
      ]
      additional_container_definitions = {
        etchosts-container = {
          name          = "etchosts-container"
          image         = "673920839910.dkr.ecr.eu-west-2.amazonaws.com/yjaf/auth:preprod"
          port_mappings = []
          cpu           = 256
          memory        = 512
          mount_points = [
            {
              sourceVolume : "hosts",
              containerPath : "/etc",
              readOnly : false
            }
          ]
          volumes = [
            {
              "name" : "hosts",
              "host" : {}
            }
          ]
          readonly_root_filesystem = false
          environment = [
            {
              "name" : "dummy",
              "value" : "requiredfortaskbuildertowork"
            },
            {
              "name" : "DD_JMXFETCH_ENABLED",
              "value" : "true"
            },
            {
              "name" : "SPRING_PROFILES_ACTIVE",
              "value" : "moj-${local.environment}"
            },
            {
              "name" : "DD_SERVICE",
              "value" : "auth"
            },
            {
              "name" : "DD_LOGS_INJECTION",
              "value" : "true"
            },
            {
              "name" : "JAVA_OPTS",
              "value" : "-Xmx1024m -Xms512m --add-modules java.se --add-exports java.base/jdk.internal.ref=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.nio=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.management/sun.management=ALL-UNNAMED --add-opens jdk.management/com.sun.management.internal=ALL-UNNAMED -Ddd.jmxfetch.enabled=true -Ddd.profiling.enabled=true -XX:FlightRecorderOptions=stackdepth=256 -Ddd.logs.injection=true -Ddd.trace.sample.rate=1 -Ddd.service=auth"
            },
            {
              "name" : "DD_ENV",
              "value" : "moj-${local.environment}"
            },
            {
              "name" : "DD_PROFILING_ENABLED",
              "value" : "true"
            },
            {
              "name" : "GATEWAY_SERVICE_URI",
              "value" : "gateway.yjaf:8080"
            }
          ]
          entryPoint = ["/bin/sh", "-c"]
          command    = ["scripts/set-hosts.sh"]
        }
      }
    },
    dal = {
      name        = "dal"
      image       = "673920839910.dkr.ecr.eu-west-2.amazonaws.com/yjaf/dal:preprod"
      task_cpu    = 512
      task_memory = 3072
      additional_environment_variables = [
        {
          "name" : "GATEWAY_SERVICE_URI"
          "value" : "gateway.yjaf:8080"
        },
        {
          "name" : "JAVA_OPTS",
          "value" : "-Xmx1024m -Xms512m -Ddd.jmxfetch.enabled=true -Ddd.profiling.enabled=true -XX:FlightRecorderOptions=stackdepth=256 -Ddd.logs.injection=true -Ddd.trace.sample.rate=1 -Ddd.service=dal -XX:-HeapDumpOnOutOfMemoryError"
        }
      ]
      enable_postgres_secret = false
    },
    sentences = {
      name        = "sentences"
      image       = "673920839910.dkr.ecr.eu-west-2.amazonaws.com/yjaf/sentences:preprod"
      task_cpu    = 512
      task_memory = 1024
      additional_environment_variables = [
        {
          "name" : "GATEWAY_SERVICE_URI"
          "value" : "gateway.yjaf:8080"
        },
        {
          "name" : "JAVA_OPTS",
          "value" : "-Xmx1024m -Xms1024m -Ddd.jmxfetch.enabled=true -Ddd.profiling.enabled=true -XX:FlightRecorderOptions=stackdepth=256 -Ddd.logs.injection=true -Ddd.trace.sample.rate=1 -Ddd.service=sentences -XX:-HeapDumpOnOutOfMemoryError"
        }
      ]
      enable_postgres_secret = false
    },
    yp = {
      name        = "yp"
      image       = "673920839910.dkr.ecr.eu-west-2.amazonaws.com/yjaf/yp:preprod"
      task_cpu    = 768
      task_memory = 3072
      additional_environment_variables = [
        {
          "name" : "GATEWAY_SERVICE_URI"
          "value" : "gateway.yjaf:8080"
        },
        {
          "name" : "JAVA_OPTS",
          "value" : "--add-modules java.se --add-exports java.base/jdk.internal.ref=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.nio=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.management/sun.management=ALL-UNNAMED --add-opens jdk.management/com.sun.management.internal=ALL-UNNAMED -Xmx2560m -Xms1024m -Ddd.jmxfetch.enabled=true -Ddd.profiling.enabled=true -XX:FlightRecorderOptions=stackdepth=256 -Ddd.logs.injection=true -Ddd.trace.sample.rate=1 -Ddd.service=yp -XX:-HeapDumpOnOutOfMemoryError"
        }
      ]
      enable_postgres_secret = false
    },
    bands = {
      name        = "bands"
      image       = "673920839910.dkr.ecr.eu-west-2.amazonaws.com/yjaf/bands:preprod"
      task_cpu    = 512
      task_memory = 1152
      additional_environment_variables = [
        {
          "name" : "GATEWAY_SERVICE_URI"
          "value" : "gateway.yjaf:8080"
        },
        {
          "name" : "JAVA_OPTS",
          "value" : "-Xmx1024m -Xms1024m -Ddd.jmxfetch.enabled=true -Ddd.profiling.enabled=true -XX:FlightRecorderOptions=stackdepth=256 -Ddd.logs.injection=true -Ddd.trace.sample.rate=1 -Ddd.service=bands -XX:-HeapDumpOnOutOfMemoryError"
        }
      ]
      enable_postgres_secret = false
    },
    bu = {
      name        = "bu"
      image       = "673920839910.dkr.ecr.eu-west-2.amazonaws.com/yjaf/bu:preprod"
      task_cpu    = 512
      task_memory = 2176
      additional_environment_variables = [
        {
          "name" : "GATEWAY_SERVICE_URI"
          "value" : "gateway.yjaf:8080"
        },
        {
          "name" : "JAVA_OPTS",
          "value" : "-Xmx1024m -Xms1024m -Ddd.jmxfetch.enabled=true -Ddd.profiling.enabled=true -XX:FlightRecorderOptions=stackdepth=256 -Ddd.logs.injection=true -Ddd.trace.sample.rate=1 -Ddd.service=bu -XX:-HeapDumpOnOutOfMemoryError"
        }
      ]
      enable_postgres_secret = false
    },
    case = {
      name                              = "case"
      image                             = "673920839910.dkr.ecr.eu-west-2.amazonaws.com/yjaf/case:preprod"
      task_cpu                          = 512
      task_memory                       = 3072
      health_check_grace_period_seconds = 420
      additional_environment_variables = [
        {
          "name" : "GATEWAY_SERVICE_URI"
          "value" : "gateway.yjaf:8080"
        },
        {
          "name" : "JAVA_OPTS",
          "value" : "-Xmx2048m -Xms1024m -Ddd.jmxfetch.enabled=true -Ddd.profiling.enabled=true -XX:FlightRecorderOptions=stackdepth=256 -Ddd.logs.injection=true -Ddd.trace.sample.rate=1 -Ddd.service=case -XX:-HeapDumpOnOutOfMemoryError"
        }
      ]
      enable_postgres_secret = false
    },
    cmm = {
      name        = "cmm"
      image       = "673920839910.dkr.ecr.eu-west-2.amazonaws.com/yjaf/cmm:preprod"
      task_cpu    = 512
      task_memory = 1152
      additional_environment_variables = [
        {
          "name" : "GATEWAY_SERVICE_URI"
          "value" : "gateway.yjaf:8080"
        },
        {
          "name" : "JVM_OPTS",
          "value" : "-Xmx1024m -Xms512m -XX:MaxPermSize=500m -Ddd.jmxfetch.enabled=true -Ddd.profiling.enabled=true -XX:FlightRecorderOptions=stackdepth=256 -Ddd.logs.injection=true -Ddd.trace.sample.rate=1 -Ddd.service=cmm -XX:-HeapDumpOnOutOfMemoryError"
        }
      ]
      enable_postgres_secret = false
    },
    conversions = {
      name        = "conversions"
      image       = "673920839910.dkr.ecr.eu-west-2.amazonaws.com/yjaf/conversions:preprod"
      task_cpu    = 512
      task_memory = 2048
      additional_environment_variables = [
        {
          "name" : "GATEWAY_SERVICE_URI"
          "value" : "gateway.yjaf:8080"
        },
        {
          "name" : "JAVA_OPTS",
          "value" : "-Xmx1536m -Xms512m -Ddd.jmxfetch.enabled=true -Ddd.profiling.enabled=true -XX:FlightRecorderOptions=stackdepth=256 -Ddd.logs.injection=true -Ddd.trace.sample.rate=1 -Ddd.service=conversions -XX:-HeapDumpOnOutOfMemoryError"
        }
      ]
      enable_postgres_secret = false
    },
    documents = {
      name        = "documents"
      image       = "673920839910.dkr.ecr.eu-west-2.amazonaws.com/yjaf/documents:preprod"
      task_cpu    = 512
      task_memory = 1638
      additional_environment_variables = [
        {
          "name" : "GATEWAY_SERVICE_URI"
          "value" : "gateway.yjaf:8080"
        },
        {
          "name" : "JAVA_OPTS",
          "value" : "-Xmx1024m -Xms512m -Ddd.jmxfetch.enabled=true -Ddd.profiling.enabled=true -XX:FlightRecorderOptions=stackdepth=256 -Ddd.logs.injection=true -Ddd.trace.sample.rate=1 -Ddd.service=documents -XX:-HeapDumpOnOutOfMemoryError"
        }
      ]
      enable_postgres_secret = false
    },
    gateway = {
      name                              = "gateway"
      internal_only                     = false
      image                             = "673920839910.dkr.ecr.eu-west-2.amazonaws.com/yjaf/gateway:preprod"
      task_cpu                          = 1024
      task_memory                       = 3072
      desired_count                     = 1
      health_check_grace_period_seconds = 600
      autoscaling_max_capacity          = 1
      ecs_task_iam_role_name            = "gateway-custom-role"
      deployment_controller             = "ECS"
      #todo add gateway sg
      additional_environment_variables = [
        {
          "name" : "GATEWAY_SERVICE_URI"
          "value" : "gateway.yjaf:8080"
        },
        {
          "name" : "JAVA_OPTS",
          "value" : "-Xmx5120m -Xms2048m --add-modules java.se --add-exports java.base/jdk.internal.ref=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.nio=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.management/sun.management=ALL-UNNAMED --add-opens jdk.management/com.sun.management.internal=ALL-UNNAMED -Ddd.jmxfetch.enabled=true -Ddd.profiling.enabled=true -XX:FlightRecorderOptions=stackdepth=256 -Ddd.logs.injection=true -Ddd.trace.sample.rate=1 -Ddd.service=gateway -XX:-HeapDumpOnOutOfMemoryError"
        }
      ]
      enable_postgres_secret = false
      additional_mount_points = [
        {
          "sourceVolume" : "logging",
          "containerPath" : "/root/logging",
          "readOnly" : false
        },
        {
          "sourceVolume" : "gateway-logs",
          "containerPath" : "/var/log/yjaf",
          "readOnly" : false
        }
      ]
      volumes = [
        {
          "name" : "logging",
          "host" : {}
        },
        {
          "name" : "gateway-logs",
          "dockerVolumeConfiguration" : {
            "scope" : "shared",
            "autoprovision" : true,
            "driver" : "local"
          }
        },
        {
          "name" : "tmpfs-1",
          "host" : {}
        }
      ]
    },
    placements = {
      name        = "placements"
      image       = "673920839910.dkr.ecr.eu-west-2.amazonaws.com/yjaf/placements:preprod"
      task_cpu    = 512
      task_memory = 2560
      additional_environment_variables = [
        {
          "name" : "GATEWAY_SERVICE_URI"
          "value" : "gateway.yjaf:8080"
        },
        {
          "name" : "JAVA_OPTS",
          "value" : "-Xmx2048m -Xms2048m --add-modules java.se --add-exports java.base/jdk.internal.ref=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.nio=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.management/sun.management=ALL-UNNAMED --add-opens jdk.management/com.sun.management.internal=ALL-UNNAMED -Ddd.jmxfetch.enabled=true -Ddd.profiling.enabled=true -XX:FlightRecorderOptions=stackdepth=256 -Ddd.logs.injection=true -Ddd.trace.sample.rate=1 -Ddd.service=placements -XX:-HeapDumpOnOutOfMemoryError"
        }
      ]
      enable_postgres_secret = false
    },
    refdata = {
      name        = "refdata"
      image       = "673920839910.dkr.ecr.eu-west-2.amazonaws.com/yjaf/refdata:preprod"
      task_cpu    = 512
      task_memory = 2662
      additional_environment_variables = [
        {
          "name" : "GATEWAY_SERVICE_URI"
          "value" : "gateway.yjaf:8080"
        },
        {
          "name" : "JAVA_OPTS",
          "value" : "-Xmx2048m -Xms2048m -Ddd.jmxfetch.enabled=true -Ddd.profiling.enabled=true -XX:FlightRecorderOptions=stackdepth=256 -Ddd.logs.injection=true -Ddd.trace.sample.rate=1 -Ddd.service=refdata -XX:-HeapDumpOnOutOfMemoryError"
        }
      ]
      enable_postgres_secret = false
    },
    returns = {
      name                              = "returns"
      image                             = "673920839910.dkr.ecr.eu-west-2.amazonaws.com/yjaf/returns:preprod"
      task_cpu                          = 512
      task_memory                       = 3328
      health_check_grace_period_seconds = 600
      additional_environment_variables = [
        {
          "name" : "GATEWAY_SERVICE_URI"
          "value" : "gateway.yjaf:8080"
        },
        {
          "name" : "JAVA_OPTS",
          "value" : "-Xmx3072m -Xms1024m --add-modules java.se --add-exports java.base/jdk.internal.ref=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.nio=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.management/sun.management=ALL-UNNAMED --add-opens jdk.management/com.sun.management.internal=ALL-UNNAMED -Ddd.jmxfetch.enabled=true -Ddd.profiling.enabled=true -XX:FlightRecorderOptions=stackdepth=256 -Ddd.logs.injection=true -Ddd.trace.sample.rate=1 -Ddd.service=returns -XX:-HeapDumpOnOutOfMemoryError"
        }
      ]
      enable_postgres_secret = false
    },
    serious-incidents = {
      name                              = "serious-incidents"
      image                             = "673920839910.dkr.ecr.eu-west-2.amazonaws.com/yjaf/serious-incidents:preprod"
      task_cpu                          = 1024
      task_memory                       = 1152
      health_check_grace_period_seconds = 120
      additional_environment_variables = [
        {
          "name" : "GATEWAY_SERVICE_URI"
          "value" : "gateway.yjaf:8080"
        },
        {
          "name" : "JAVA_OPTS",
          "value" : "-Xmx1024m -Xms1024m -Ddd.jmxfetch.enabled=true -Ddd.profiling.enabled=true -XX:FlightRecorderOptions=stackdepth=256 -Ddd.logs.injection=true -Ddd.trace.sample.rate=1 -Ddd.service=serious-incidents -XX:-HeapDumpOnOutOfMemoryError"
        }
      ]
      enable_postgres_secret = false
    },
    transfers = {
      name        = "transfers"
      image       = "673920839910.dkr.ecr.eu-west-2.amazonaws.com/yjaf/transfers:preprod"
      task_cpu    = 512
      task_memory = 1152
      additional_environment_variables = [
        {
          "name" : "GATEWAY_SERVICE_URI"
          "value" : "gateway.yjaf:8080"
        },
        {
          "name" : "JAVA_OPTS",
          "value" : "-Xmx1024m -Xms512m --add-modules java.se --add-exports java.base/jdk.internal.ref=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.nio=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.management/sun.management=ALL-UNNAMED --add-opens jdk.management/com.sun.management.internal=ALL-UNNAMED -Ddd.jmxfetch.enabled=true -Ddd.profiling.enabled=true -XX:FlightRecorderOptions=stackdepth=256 -Ddd.logs.injection=true -Ddd.trace.sample.rate=1 -Ddd.service=transfers -XX:-HeapDumpOnOutOfMemoryError"
        }
      ]
      enable_postgres_secret = false
    },
    transitions = {
      name                              = "transitions"
      image                             = "673920839910.dkr.ecr.eu-west-2.amazonaws.com/yjaf/transitions:preprod"
      task_cpu                          = 512
      task_memory                       = 1152
      health_check_grace_period_seconds = 120
      additional_environment_variables = [
        {
          "name" : "GATEWAY_SERVICE_URI"
          "value" : "gateway.yjaf:8080"
        },
        {
          "name" : "JAVA_OPTS",
          "value" : "-Xmx1024m -Xms512m --add-modules java.se --add-exports java.base/jdk.internal.ref=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.nio=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.management/sun.management=ALL-UNNAMED --add-opens jdk.management/com.sun.management.internal=ALL-UNNAMED -Ddd.jmxfetch.enabled=true -Ddd.profiling.enabled=true -XX:FlightRecorderOptions=stackdepth=256 -Ddd.logs.injection=true -Ddd.trace.sample.rate=1 -Ddd.service=transitions -XX:-HeapDumpOnOutOfMemoryError"
        }
      ]
      enable_postgres_secret = false
    },
    ui = {
      name                              = "ui"
      image                             = "673920839910.dkr.ecr.eu-west-2.amazonaws.com/yjaf/ui:preprod"
      task_cpu                          = 256
      task_memory                       = 1024
      health_check_grace_period_seconds = 120
      additional_environment_variables = [
        {
          "name" : "GATEWAY_SERVICE_URI"
          "value" : "gateway.yjaf:8080"
        },
        {
          "name" : "JVM_OPTS",
          "value" : "-Xmx1024m -Xms512m -XX:MaxPermSize=500m"
        }
      ]
      enable_postgres_secret = false
      additional_mount_points = [
        {
          sourceVolume : "cache",
          containerPath : "/var/cache/nginx",
          readOnly : false
        },
        {
          sourceVolume : "conf",
          containerPath : "/etc/nginx",
          readOnly : false
        },
        {
          sourceVolume : "tmpfs-1",
          containerPath : "/var/run",
          readOnly : false
        }
      ]
      volumes = [
        {
          "name" : "cache",
          "host" : {}
        },
        {
          "name" : "conf",
          "host" : {}
        },
        {
          "name" : "tmpfs-1",
          "host" : {}
        }
      ]
    },
    views = {
      name        = "views"
      image       = "673920839910.dkr.ecr.eu-west-2.amazonaws.com/yjaf/views:preprod"
      task_cpu    = 512
      task_memory = 2048
      additional_environment_variables = [
        {
          "name" : "GATEWAY_SERVICE_URI"
          "value" : "gateway.yjaf:8080"
        },
        {
          "name" : "JAVA_OPTS",
          "value" : "-Xmx1536m -Xms1024m -Ddd.jmxfetch.enabled=true -Ddd.profiling.enabled=true -XX:FlightRecorderOptions=stackdepth=256 -Ddd.logs.injection=true -Ddd.trace.sample.rate=1 -Ddd.service=views -XX:-HeapDumpOnOutOfMemoryError"
        }
      ]
      enable_postgres_secret = false
    },
    workflow = {
      name                              = "workflow"
      image                             = "673920839910.dkr.ecr.eu-west-2.amazonaws.com/yjaf/workflow:preprod"
      task_cpu                          = 1024
      task_memory                       = 3584
      health_check_grace_period_seconds = 420
      additional_environment_variables = [
        {
          "name" : "GATEWAY_SERVICE_URI"
          "value" : "gateway.yjaf:8080"
        },
        {
          "name" : "JAVA_OPTS",
          "value" : "-Xmx2048m -Xms512m -Ddd.jmxfetch.enabled=true -Ddd.profiling.enabled=true -XX:FlightRecorderOptions=stackdepth=256 -Ddd.logs.injection=true -Ddd.trace.sample.rate=1 -Ddd.service=workflow -XX:-HeapDumpOnOutOfMemoryError"
        }
      ]
      enable_postgres_secret = false
    }
  }
}
