# User: arn:aws:sts::***:assumed-role/MemberInfrastructureAccess/aws-go-sdk-1670248274835387038 is not authorized to perform: applicationinsights:CreateApplication
# resource "aws_applicationinsights_application" "oracle" {
#   resource_group_name = aws_resourcegroups_group.oracle.name
#}

resource "aws_resourcegroups_group" "oracle" {
  name = "oracle"

  resource_query {
    query = <<JSON
    {
        "ResourceTypeFilters": [
          "AWS::EC2::Instance"
        ],
        "TagFilters": [
          {
            "Key": "environment-name",
            "Values": [
              "nomis-development"
            ]
          },
          {
            "Key": "application",
            "Values": [
              "nomis"
            ]
          }
        ]
      }
JSON
  }
}