# AWS Codedeploy
This module creates a codedeploy application and deployment group.

## Usage
```hcl
module "codedeploy" {
  source = "../../../..//terraform/codedeploy" #todo fix this source later when we move to github modules

  services = ["service1", "service2"]
  ecs_cluster_name = "ecs-cluster-name"
}
```


