# ssm-documents

This directory contains the Terraform code to create the SSM Command documents used by the Nomis service.

These are uploaded into each nomis-\* environment when ec2-common.tf runs or if they're only specified in a particular ec2-<instance_type>.tf then they will only be uploaded to the environment where that instance type is deployed.

SSM Command documents are basically "scripts" that can be run against EC2 instances or other targets. Starting point for understanding these and their capabilities is the [AWS documentation](https://docs.aws.amazon.com/systems-manager/latest/userguide/execute-remote-commands.html)

While there are a LOT of pre-built AWS official ones they are all comprised of the same building blocks: [AWS Systems Manager Run Command document plugin reference](https://docs.aws.amazon.com/systems-manager/latest/userguide/ssm-plugins.html)

## individual-ssm-documents

### s3auditupload.yaml.tftmpl

Calls a specific ansible playbook directly from the [modernisation-platform-configuration-management](https://github.com/ministryofjustice/modernisation-platform-configuration-management) repository.

Note that this particular ssm document runs using Python3.9 so cannot be run on the weblogic/rhel6-10 AMI based machines which only have Python3.6 installed.

## generic run-ansible-patches ssm document

This ssm document is used to run the same site.yml file in [modernisation-platform-configuration-management](https://github.com/ministryofjustice/modernisation-platform-configuration-management) allowing you to run individual roles against particular servers (or groups).

The target selection is actually specified via the SSM document UI and not the document itself. This will probably evolve over time.

IMPORTANT: You do need to make sure that the correct tags are present to allow the role you're calling to be run at a particular target. See [using targets and rate controls](https://docs.aws.amazon.com/systems-manager/latest/userguide/send-commands-multiple.html) for sending commands to a fleet of instances.

### pre-requisites

1. The EC2 instance running the role must have ssm:GetDocuments permissions.
   - Added to the ssm_custom role in ec2_common.tf so should apply to everything going forwards
   - Used by the ssm document to get the relevant ansible code from GitHub using aws:downloadContent action/GitHub
2. There must be an ssm:parameter containing a GitHub token available in the account that the instance is running in.
   - If this isn't supplied then the github api will be rate limited and the content download step will fail
   - At the moment this has been copied to each environment manually as github-ci-user-pat
     - The intention is for this to be replaced by something that's being managed and uploaded automatically
3. Currently LINUX ONLY
4. The SSM Agent must be running on the target for these to work

### running

TODO: Add a specific reference to tags here

### discovering what's been run against a given EC2 instance target

TODO: Add a set of steps for how to do this here

### debugging/output

If you specify an output S3 bucket then it will be send to a folder (a GUID unless specified) and each sub-folder relates to a step in the ssm document.

Otherwise you can look in the SSM document history for the command and see the output there. Reading the output is pretty straightforward.

It is worth being aware that if you use the aws:downloadContent plugin that files are actually running from a downloads/ directory that's not on the target machine itself.
