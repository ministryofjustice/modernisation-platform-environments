# ssm-documents

This directory contains the Terraform code to create the SSM documents used by the Nomis service.

See s3auditupload.yaml.tftmpl where a document is being created that uses ansible roles from the [modernisation-platform-configuration-management](https://github.com/ministryofjustice/modernisation-platform-configuration-management) repository.

Note that this particular ssm document runs using Python3.9 so cannot be run on the weblogic/rhel6-10 AMI based machines.
