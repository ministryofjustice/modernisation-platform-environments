locals {
  internal_listeners = {
    internal_listener = {
      port     = 8080
      protocol = "HTTP"
      forward = {
        target_group_key = "ui-target-group-1"
      }
      rules = {
        ui = {
          priority = 1
          actions = [
            {
              type             = "forward"
              target_group_key = "ui-target-group-1"
            }
          ]
          conditions = [{
            path_pattern = {
              values = ["/ui", "/api/v1/ui*"]
            }
          }]
        },
        dal = {
          priority = 2
          actions = [
            {
              type             = "forward"
              target_group_key = "dal-target-group-1"
            }
          ]
          conditions = [{
            path_pattern = {
              values = ["/api/v1/dal*"]
            }
          }]
        },
        yp = {
          priority = 4
          actions = [
            {
              type             = "forward"
              target_group_key = "yp-target-group-1"
            }
          ]
          conditions = [{
            path_pattern = {
              values = ["/api/v1/yps*", "/api/v1/yp*"]
            }
          }]
        }
        auth = {
          priority = 5
          actions = [
            {
              type             = "forward"
              target_group_key = "auth-target-group-1"
            }
          ]
          conditions = [{
            path_pattern = {
              values = ["/api/v1/users*", "/api/v1/auth*"]
            }
          }]
        },
        bands = {
          priority = 6
          actions = [
            {
              type             = "forward"
              target_group_key = "bands-target-group-1"
            }
          ]
          conditions = [{
            path_pattern = {
              values = ["/api/v1/bands*"]
            }
          }]
        }
        bu = {
          priority = 7
          actions = [
            {
              type             = "forward"
              target_group_key = "bu-target-group-1"
            }
          ]
          conditions = [{
            path_pattern = {
              values = ["/api/v1/bu*"]
            }
          }]
        }
        case = {
          priority = 8
          actions = [
            {
              type             = "forward"
              target_group_key = "case-target-group-1"
            }
          ]
          conditions = [{
            path_pattern = {
              values = ["/api/v1/case*"]
            }
          }]
        },
        cmm = {
          priority = 9
          actions = [
            {
              type             = "forward"
              target_group_key = "cmm-target-group-1"
            }
          ]
          conditions = [{
            path_pattern = {
              values = ["/api/v1/cmm*"]
            }
          }]
        }
        conversions = {
          priority = 10
          actions = [
            {
              type             = "forward"
              target_group_key = "conversions-target-group-1"
            }
          ]
          conditions = [{
            path_pattern = {
              values = ["/api/v1/conversions*"]
            }
          }]
        }
        documents = {
          priority = 11
          actions = [
            {
              type             = "forward"
              target_group_key = "documents-target-group-1"
            }
          ]
          conditions = [{
            path_pattern = {
              values = ["/api/v1/docs*", "/api/v1/documents*"]
            }
          }]
        },
        gateway = {
          priority = 12
          actions = [
            {
              type             = "forward"
              target_group_key = "gateway-target-group-1"
            }
          ]
          conditions = [{
            path_pattern = {
              values = ["/secure/api*"]
            }
          }]
        }
        placements = {
          priority = 13
          actions = [
            {
              type             = "forward"
              target_group_key = "placements-target-group-1"
            }
          ]
          conditions = [{
            path_pattern = {
              values = ["/api/v1/placements*"]
            }
          }]
        }
        refdata = {
          priority = 14
          actions = [
            {
              type             = "forward"
              target_group_key = "refdata-target-group-1"
            }
          ]
          conditions = [{
            path_pattern = {
              values = ["/api/v1/refdata*", "/api/v1/ref*"]
            }
          }]
        },
        returns = {
          priority = 15
          actions = [
            {
              type             = "forward"
              target_group_key = "returns-target-group-1"
            }
          ]
          conditions = [{
            path_pattern = {
              values = ["/api/v1/returns*"]
            }
          }]
        }
        serious-incidents = {
          priority = 16
          actions = [
            {
              type             = "forward"
              target_group_key = "serious-incidents-target-group-1"
            }
          ]
          conditions = [{
            path_pattern = {
              values = ["/serious-incidents", "/api/v1/serious-incidents*"]
            }
          }]
        }
        transfers = {
          priority = 17
          actions = [
            {
              type             = "forward"
              target_group_key = "transfers-target-group-1"
            }
          ]
          conditions = [{
            path_pattern = {
              values = ["/api/v1/transfers*"]
            }
          }]
        },
        views = {
          priority = 18
          actions = [
            {
              type             = "forward"
              target_group_key = "views-target-group-1"
            }
          ]
          conditions = [{
            path_pattern = {
              values = ["/api/v1/views*"]
            }
          }]
        }
        workflow = {
          priority = 19
          actions = [
            {
              type             = "forward"
              target_group_key = "workflow-target-group-1"
            }
          ]
          conditions = [{
            path_pattern = {
              values = ["/api/v1/workflow*"]
            }
          }]
        },
        sentences = {
          priority = 20
          actions = [
            {
              type             = "forward"
              target_group_key = "sentences-target-group-1"
            }
          ]
          conditions = [{
            path_pattern = {
              values = ["/api/v1/sentence-calc*", "/api/v1/sentences*"]
            }
          }]
        }
        transitions = {
          priority = 21
          actions = [
            {
              type             = "forward"
              target_group_key = "transitions-target-group-1"
            }
          ]
          conditions = [{
            path_pattern = {
              values = ["/transition", "/api/v1/transition*"]
            }
          }]
        },
        # The following rules are for healthchecks
        ui-healthcheck = {
          priority = 22
          actions = [
            {
              type             = "forward"
              target_group_key = "ui-target-group-1"
            }
          ]
          conditions = [{
            host_header = {
              values = ["ui.${local.environment}.yjaf"]
            }
          }]
        },
        dal-healthcheck = {
          priority = 23
          actions = [
            {
              type             = "forward"
              target_group_key = "dal-target-group-1"
            }
          ]
          conditions = [{
            host_header = {
              values = ["dal.${local.environment}.yjaf"]
            }
          }]
        },
        yp-healthcheck = {
          priority = 24
          actions = [
            {
              type             = "forward"
              target_group_key = "yp-target-group-1"
            }
          ]
          conditions = [{
            host_header = {
              values = ["yp.${local.environment}.yjaf"]
            }
          }]
        }
        auth-healthcheck = {
          priority = 25
          actions = [
            {
              type             = "forward"
              target_group_key = "auth-target-group-1"
            }
          ]
          conditions = [{
            host_header = {
              values = ["auth.${local.environment}.yjaf"]
            }
          }]
        },
        bands-healthcheck = {
          priority = 26
          actions = [
            {
              type             = "forward"
              target_group_key = "bands-target-group-1"
            }
          ]
          conditions = [{
            host_header = {
              values = ["bands.${local.environment}.yjaf"]
            }
          }]
        }
        bu-healthcheck = {
          priority = 27
          actions = [
            {
              type             = "forward"
              target_group_key = "bu-target-group-1"
            }
          ]
          conditions = [{
            host_header = {
              values = ["bu.${local.environment}.yjaf"]
            }
          }]
        }
        case-healthcheck = {
          priority = 28
          actions = [
            {
              type             = "forward"
              target_group_key = "case-target-group-1"
            }
          ]
          conditions = [{
            host_header = {
              values = ["case.${local.environment}.yjaf"]
            }
          }]
        },
        cmm-healthcheck = {
          priority = 29
          actions = [
            {
              type             = "forward"
              target_group_key = "cmm-target-group-1"
            }
          ]
          conditions = [{
            host_header = {
              values = ["cmm.${local.environment}.yjaf"]
            }
          }]
        }
        conversions-healthcheck = {
          priority = 30
          actions = [
            {
              type             = "forward"
              target_group_key = "conversions-target-group-1"
            }
          ]
          conditions = [{
            host_header = {
              values = ["conversions.${local.environment}.yjaf"]
            }
          }]
        }
        documents-healthcheck = {
          priority = 31
          actions = [
            {
              type             = "forward"
              target_group_key = "documents-target-group-1"
            }
          ]
          conditions = [{
            host_header = {
              values = ["documents.${local.environment}.yjaf"]
            }
          }]
        },
        gateway-healthcheck = {
          priority = 32
          actions = [
            {
              type             = "forward"
              target_group_key = "gateway-target-group-1"
            }
          ]
          conditions = [{
            host_header = {
              values = ["gateway.${local.environment}.yjaf"]
            }
          }]
        }
        placements-healthcheck = {
          priority = 33
          actions = [
            {
              type             = "forward"
              target_group_key = "placements-target-group-1"
            }
          ]
          conditions = [{
            host_header = {
              values = ["placements.${local.environment}.yjaf"]
            }
          }]
        }
        refdata-healthcheck = {
          priority = 34
          actions = [
            {
              type             = "forward"
              target_group_key = "refdata-target-group-1"
            }
          ]
          conditions = [{
            host_header = {
              values = ["refdata.${local.environment}.yjaf"]
            }
          }]
        },
        returns-healthcheck = {
          priority = 35
          actions = [
            {
              type             = "forward"
              target_group_key = "returns-target-group-1"
            }
          ]
          conditions = [{
            host_header = {
              values = ["returns.${local.environment}.yjaf"]
            }
          }]
        }
        serious-incidents-healthcheck = {
          priority = 36
          actions = [
            {
              type             = "forward"
              target_group_key = "serious-incidents-target-group-1"
            }
          ]
          conditions = [{
            host_header = {
              values = ["serious-incidents.${local.environment}.yjaf"]
            }
          }]
        }
        transfers-healthcheck = {
          priority = 37
          actions = [
            {
              type             = "forward"
              target_group_key = "transfers-target-group-1"
            }
          ]
          conditions = [{
            host_header = {
              values = ["transfers.${local.environment}.yjaf"]
            }
          }]
        },
        views-healthcheck = {
          priority = 38
          actions = [
            {
              type             = "forward"
              target_group_key = "views-target-group-1"
            }
          ]
          conditions = [{
            host_header = {
              values = ["views.${local.environment}.yjaf"]
            }
          }]
        }
        workflow-healthcheck = {
          priority = 39
          actions = [
            {
              type             = "forward"
              target_group_key = "workflow-target-group-1"
            }
          ]
          conditions = [{
            host_header = {
              values = ["workflow.${local.environment}.yjaf"]
            }
          }]
        },
        sentences-healthcheck = {
          priority = 40
          actions = [
            {
              type             = "forward"
              target_group_key = "sentences-target-group-1"
            }
          ]
          conditions = [{
            host_header = {
              values = ["sentences.${local.environment}.yjaf"]
            }
          }]
        }
        transitions-healthcheck = {
          priority = 41
          actions = [
            {
              type             = "forward"
              target_group_key = "transitions-target-group-1"
            }
          ]
          conditions = [{
            host_header = {
              values = ["transitions.${local.environment}.yjaf"]
            }
          }]
        }



      }
    }
  }
}
