resource "aws_applicationinsights_application" "oracle" {
  resource_group_name = aws_resourcegroups_group.oracle.name
}

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