locals {

  iam_policy_statements_ec2 = {
    web = [ # allow maintenance mode script to adjust priorities
      {
        effect = "Allow"
        actions = [
          "elasticloadbalancing:Describe*",
        ]
        resources = ["*"]
      },
      {
        effect = "Allow"
        actions = [
          "elasticloadbalancing:SetRulePriorities",
        ]
        resources = [
          "arn:aws:elasticloadbalancing:*:*:listener-rule/app/private-lb/*",
        ]
      }
    ]
  }

}
