locals {

  iam_policy_statements_ec2 = {
    web = [
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
