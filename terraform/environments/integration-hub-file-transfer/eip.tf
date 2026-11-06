resource "aws_eip" "this" {
  count  = length(local.transfer_subnet_ids)
  domain = "vpc"
  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-transfer-server-${count.index + 1}"
    }
  )

  # Partners allow-list these addresses on their own firewalls; losing one
  # would silently block every sender behind that firewall rule.
  lifecycle {
    prevent_destroy = true
  }
}