locals {
  internal_listeners = {
    internal_listener = {
      port                                 = 8080
      protocol                             = "HTTP"
      routing_http_response_server_enabled = true
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
        assets = {
          priority = 3
          actions = [
            {
              type             = "forward"
              target_group_key = "assets-target-group-1"
            }
          ]
          conditions = [{
            path_pattern = {
              values = ["/api/v1/assets*"]
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
        },
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
        },
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
        },
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
        },
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
        },
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
        connectivity = {
          priority = 12
          actions = [
            {
              type             = "forward"
              target_group_key = "connectivity-target-group-1"
            }
          ]
          conditions = [{
            path_pattern = {
              values = ["/api/v1/connectivity*"]
            }
          }]
        },
        gateway-internal = {
          priority = 22
          actions = [
            {
              type             = "forward"
              target_group_key = "gateway-internal-target-group-1"
            }
          ]
          conditions = [{
            path_pattern = {
              values = ["/secure/api*"]
            }
          }]
        },
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
        },
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
        },
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
        },
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
        },
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
        },
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
        dal_health = {
          priority = 23
          actions = [
            {
              type             = "forward"
              target_group_key = "dal-target-group-1"
            }
          ]
          conditions = [{ #header condition for dal
            http_header = {
              http_header_name = "service-health"
              values           = ["dal"]
            }
          }]
        },
        yp_health = {
          priority = 24
          actions = [
            {
              type             = "forward"
              target_group_key = "yp-target-group-2"
            }
          ]
          conditions = [{ #header condition for yp
            http_header = {
              http_header_name = "service-health"
              values           = ["yp"]
            }
          }]
        },
        auth_health = {
          priority = 25
          actions = [
            {
              type             = "forward"
              target_group_key = "auth-target-group-2"
            }
          ]
          conditions = [{ #header condition for auth
            http_header = {
              http_header_name = "service-health"
              values           = ["auth"]
            }
          }]
        },
        bands_health = {
          priority = 26
          actions = [
            {
              type             = "forward"
              target_group_key = "bands-target-group-2"
            }
          ]
          conditions = [{ #header condition for bands
            http_header = {
              http_header_name = "service-health"
              values           = ["bands"]
            }
          }]
        },
        bu_health = {
          priority = 27
          actions = [
            {
              type             = "forward"
              target_group_key = "bu-target-group-2"
            }
          ]
          conditions = [{ #header condition for bu
            http_header = {
              http_header_name = "service-health"
              values           = ["bu"]
            }
          }]
        },
        case_health = {
          priority = 28
          actions = [
            {
              type             = "forward"
              target_group_key = "case-target-group-2"
            }
          ]
          conditions = [{ #header condition for case
            http_header = {
              http_header_name = "service-health"
              values           = ["case"]
            }
          }]
        },
        cmm_health = {
          priority = 29
          actions = [
            {
              type             = "forward"
              target_group_key = "cmm-target-group-2"
            }
          ]
          conditions = [{ #header condition for cmm
            http_header = {
              http_header_name = "service-health"
              values           = ["cmm"]
            }
          }]
        },
        conversions_health = {
          priority = 30
          actions = [
            {
              type             = "forward"
              target_group_key = "conversions-target-group-2"
            }
          ]
          conditions = [{ #header condition for conversions
            http_header = {
              http_header_name = "service-health"
              values           = ["conversions"]
            }
          }]
        },
        documents_health = {
          priority = 31
          actions = [
            {
              type             = "forward"
              target_group_key = "documents-target-group-2"
            }
          ]
          conditions = [{ #header condition for documents
            http_header = {
              http_header_name = "service-health"
              values           = ["documents"]
            }
          }]
        },
        gateway-internal_health = {
          priority = 32
          actions = [
            {
              type             = "forward"
              target_group_key = "gateway-internal-target-group-1"
            }
          ]
          conditions = [{ #header condition for gateway-internal
            http_header = {
              http_header_name = "service-health"
              values           = ["gateway-internal"]
            }
          }]
        },
        placements_health = {
          priority = 33
          actions = [
            {
              type             = "forward"
              target_group_key = "placements-target-group-2"
            }
          ]
          conditions = [{ #header condition for placements
            http_header = {
              http_header_name = "service-health"
              values           = ["placements"]
            }
          }]
        },
        refdata_health = {
          priority = 34
          actions = [
            {
              type             = "forward"
              target_group_key = "refdata-target-group-2"
            }
          ]
          conditions = [{ #header condition for  refdata
            http_header = {
              http_header_name = "service-health"
              values           = ["refdata"]
            }
          }]
        },
        returns_health = {
          priority = 35
          actions = [
            {
              type             = "forward"
              target_group_key = "returns-target-group-1"
            }
          ]
          conditions = [{ #header condition for returns
            http_header = {
              http_header_name = "service-health"
              values           = ["returns"]
            }
          }]
        },
        serious-incidents_health = {
          priority = 36
          actions = [
            {
              type             = "forward"
              target_group_key = "serious-incidents-target-group-2"
            }
          ]
          conditions = [{ #header condition for serious-incidents
            http_header = {
              http_header_name = "service-health"
              values           = ["serious-incidents"]
            }
          }]
        },
        transfers_health = {
          priority = 37
          actions = [
            {
              type             = "forward"
              target_group_key = "transfers-target-group-2"
            }
          ]
          conditions = [{ #header condition for transfers
            http_header = {
              http_header_name = "service-health"
              values           = ["transfers"]
            }
          }]
        },
        views_health = {
          priority = 38
          actions = [
            {
              type             = "forward"
              target_group_key = "views-target-group-2"
            }
          ]
          conditions = [{ #header condition for views
            http_header = {
              http_header_name = "service-health"
              values           = ["views"]
            }
          }]
        },
        workflow_health = {
          priority = 39
          actions = [
            {
              type             = "forward"
              target_group_key = "workflow-target-group-2"
            }
          ]
          conditions = [{ #header condition for workflow
            http_header = {
              http_header_name = "service-health"
              values           = ["workflow"]
            }
          }]
        },
        sentences_health = {
          priority = 40
          actions = [
            {
              type             = "forward"
              target_group_key = "sentences-target-group-2"
            }
          ]
          conditions = [{ #header condition for sentences
            http_header = {
              http_header_name = "service-health"
              values           = ["sentences"]
            }
          }]
        },
        transitions_health = {
          priority = 41
          actions = [
            {
              type             = "forward"
              target_group_key = "transitions-target-group-2"
            }
          ]
          conditions = [{ #header condition for transitions
            http_header = {
              http_header_name = "service-health"
              values           = ["transitions"]
            }
          }]
        },
        assets_health = {
          priority = 42
          actions = [
            {
              type             = "forward"
              target_group_key = "assets-target-group-1"
            }
          ]
          conditions = [{ #header condition for assets
            http_header = {
              http_header_name = "service-health"
              values           = ["assets"]
            }
          }]
        },
        connectivity_health = {
          priority = 43
          actions = [
            {
              type             = "forward"
              target_group_key = "connectivity-target-group-2"
            }
          ]
          conditions = [{ #header condition for connectivity
            http_header = {
              http_header_name = "service-health"
              values           = ["connectivity"]
            }
          }]
        }
      }
    }
  }
}
