locals {
  access_grants_instance_arn = "arn:aws:s3:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:access-grants/default"
  pickup_grants = merge({}, [for id, recipient in local.recipients : {
    for group, group_id in recipient.authorised_groups : "${id}/${group}" => {
      recipient_id = id
      group_id     = group_id
    }
  }]...)
}