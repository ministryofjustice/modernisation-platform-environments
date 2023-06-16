resource "aws_cloudtrail" "trail" {
    name                          = "${local.project}-cloud-trail-${local.environment}"
    s3_bucket_name                = module.s3_audit_logging_bucket[0].bucket_id
    s3_key_prefix                 = "cloud_trail"
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