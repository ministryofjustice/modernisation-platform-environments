locals {
  sns_topic_subscriptions_list = flatten([
    for sns_key, sns_value in var.sns_topics : [
      for subscription_key, subscription_value in sns_value.subscriptions : {
        key = "${sns_key}-${subscription_key}"
        value = merge(subscription_value, {
          sns_topic_name = sns_key
        })
    }]
  ])

  sns_topic_subscriptions = {
    for item in local.sns_topic_subscriptions_list : item.key => item.value
  }
}

resource "aws_sns_topic" "this" {
  for_each = var.sns_topics

  name              = each.key
  display_name      = each.value.display_name
  kms_master_key_id = try(var.environment.kms_keys[each.value.kms_master_key_id].arn, each.value.kms_master_key_id)

  tags = merge(local.tags, {
    Name = each.key
  })
}

resource "aws_sns_topic_subscription" "this" {
  for_each = local.sns_topic_subscriptions

  topic_arn     = aws_sns_topic.this[each.value.sns_topic_name].arn
  protocol      = each.value.protocol
  endpoint      = each.value.endpoint
  filter_policy = each.value.filter_policy
}
