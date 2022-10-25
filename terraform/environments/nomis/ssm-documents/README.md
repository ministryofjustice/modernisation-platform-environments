# ssm-documents

This directory contains the Terraform code to create the SSM documents used by the Nomis service.

See s3auditupload.yaml.tftmpl where a document is being created that uses ansible roles from the [modernisation-platform-configuration-management](https://github.com/ministryofjustice/modernisation-platform-configuration-management) repository.

Note that this particular ssm document runs using Python3.9 so cannot be run on the weblogic/rhel6-10 AMI based machines which only have Python3.6 installed.

## run-ansible-patches ssm document

This document is used to run the same site.yml file with roles against particular servers.

### pre-requisites

1. The EC2 instance running the role must have ssm:GetDocuments permissions.
2. There must be an ssm:parameter for a GitHub token available in the account that the instance is running in.
   - at the moment this only exists in nomis-test and nomis-development
3. Currently LINUX ONLY
