resource "aws_cloudtrail" "trail" {
    name                          = "${local.project}-cloud-trail-${local.environment}"
    include_global_service_events = true

    event_selector {
        read_write_type           = "All"
        include_management_events = true
    }
    tags = merge(
        local.all_tags,
        {
        Name          = "${local.project}-cloud-trail-${local.environment}"
        Resource_Type = "Cloud Trail"
        Jira          = "DPR-471"
        }
    )    
}