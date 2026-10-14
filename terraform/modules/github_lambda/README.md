# Github Lambda Module

### Overview
This module provisions the components required in order to trigger Github Actions workflows in a target ministryofjustice repository
on a schedule.

Github Actions scheduled workflows can occasionally fail to trigger on time, and Github explicitly documents this as a known limitation - there are also
cases where the schedule can appear to be completely ignored.  This module provides a workaround for this issue by using a Lambda function to trigger the workflow on a schedule. This module provisions:
- An EventBridge Scheduler, which can be leveraged in order to set the time(s) at which the workflow should be triggered
- A Lambda function (written in Python) which is responsible for triggering the workflow in the target repository
- Supporting IAM roles and policies to allow the Lambda function to execute and trigger the workflow
- Supporting KMS and SQS resources as appropriate
- The required configuration to enable [Outbound Identity Federation](https://aws.amazon.com/identity/federation/outbound-federation/) in the target AWS account

This module works in combination with [OCTO STS](https://edu.chainguard.dev/open-source/octo-sts/overview/) to establish connectivity with the target github repository.

### Usage

Below you will see the minimal configuration you require within your `main.tf` file (for the subdirectory that calls this module):

```
module "github_workflow_scheduler" {
  source                      = "../../modules/github_lambda"
  aws_account_id              = data.aws_caller_identity.current.id
  project_name                = "projectname-github-trigger"
  github_workflows            = local.github_workflows
}
```

Then in the relevant `locals_environment.tf` file, create a github_workflows locals configuration similar to the following:

```
github_workflows = {
    my-workflow-daily-trigger = {
      identity  = "platform-operations"
      inputs    = {}

      ref      = "main"
      repo     = "reponamegoeshere"
      schedule = "cron(15 13 * * ? *)"
      timezone = "Europe/London"
      workflow = "hello-world.yml"
    }
  }
```

Once you have Terraform applied this configuration, you will need to create a `.github/chainguard/${IDENTITY}.sts.yaml` in the relevant github repository (or repositories) containing the Github Actions workflow(s), as per step one [here](https://developer-portal.service.justice.gov.uk/github/github-authentication-for-automated-workloads#:~:text=Use%20Octo%20STS%20for%20cross%2Drepository%20access).

Supply the following:
- Issuer: This should match the [Outbound Identity Federation](https://aws.amazon.com/identity/federation/outbound-federation/) Token Issuer URL in your account (see Account Settings under IAM in the console if you cannot find it)  
- Subject: This should match the ARN of the IAM role created for the lambda [here](./iam.tf#L162-L165))

Ensure that you also give

```
permissions:
  actions: write
```

Note: The ${IDENTITY} in the filename above must match the identity value you have set in the `locals_environment.yaml` file.

The EventBridge scheduler will now trigger the Lambda function on the schedule you have defined in your `locals_environment.tf` file.

If you wish you test this before your scheduled build, you can trigger the Lambda manually from the AWS Console - ensure that you provide the following JSON when triggering a test event:

```
{
  "identity": "identitynamegoeshere",
  "repo": "reponamegoeshere",
  "ref": "main",
  "workflow": "hello-world.yml"
}
```

This will trigger the relevant Github Action workflow for your repository.

