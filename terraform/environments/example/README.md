# Service Runbook

<!-- This is a template that should be populated by the development team when moving to the modernisation platform, but also reviewed and kept up to date.
To ensure that people looking at your runbook can get the information they need quickly, your runbook should be short but clear. Throughout, only use acronyms if you’re confident that someone who has just been woken up at 3am would understand them. -->

_If you have any questions surrounding this page please post in the `#team-name` channel._

## Mandatory Information

### **Last review date:**

last_reviewed_on: 2022-10-07

### **Description:**

The purpose of this repository is to provide example code which can be copied and re-used when building items on the Modernisation Platform with Terraform. In most cases the code will contain references to "Example" (or "example") which can be changed. A lot of the variables in use are stored in the application_variables.json enabling different variables to be used for different accounts.

DO NOT, however, store any passwords in this code. If they are required use the secrets.tf code to get a secure, and unlisted, version stored in the secrets within AWS.

### **Service URLs:**

This is not an actual service, so there are no URLS.

### **Incident response hours:**

N/A

### **Incident contact details:**

N/A

### **Service team contact:**

Please post in #ask-modernisation-platform

### **Hosting environment:**

Modernisation Platform

## Optional

### EC2 - ec2.tf

The EC2 code requires security groups to be used which are created prior to the EC2 service. To ensure this happens there is a step in the code (depends_on) which ensures that is complete before the EC2 is built. In general, the security group is built very quickly so this causes no delay.
There is a section in there which increases the root volume to 20Gb rather than the default 8Gb that would be used based on the server type. This may not be needed and can be removed.

Some of the other steps use variables stored in application_variables.json - `local.app_variables.accounts[local.environment]`. This is set in locals.tf to point to the correct location - `app_variables = jsondecode(file("./application_variables.json"))`. If another file/location is used this will need to be changed.

### Volumes - volumes.tf

To keep volume builds separate they have been included in another code block. If additional volumes are needed in EC2 instances they can be added here. They also need to be attached as shown in the code

An additional section was included at the top of the code to set the kms key for encryption purposes. The key is shown in the volume build section (aws_kms_key.ec2.arn).

### Secrets - secrets.tf

In this code the secrets is only used to generate a secret for the database control ID. All the sections are needed for each secret that is created. This is the way we keep the passwords secure and hidden.

### Database - rds.tf

The code is based on an SQL database at 5.7. This is not codified but can be if you add the options to application_variables.json. Again most of the settings are in there apart from the password which is accessed through secrets. It is relatively straight forward and the type of database and engine can be amended as needed (.e.g Oracle, 19c).

One thing to note - AWS quite often update the RDS supported versions and force a code change. If you are on an older database version that is being discontinued you will need to amend the RDS instance to take this into account.

Building the database can take a considerable amount of time.

### S3

This is a piece of code that uses a module which will do a number of settings in the background (via the code in the source referenced). In this example things are entered manually but, again, could be set as variables which will be needed if you require different settings between development and production, for example.

The lifecycle rules are optional but you may want to continue using those listed.

### Load balancer - loadbalacer.tf, loadbalancer2.tf

The former of these uses the resource to build everything and the latter uses the module. In the module version the ingress and egress rules are set maually (coded) based on the settings taken from the listed code. In the resource version they are codified and the data is picked up from the application_variables.json.

In both cases a target group is created and in the loadbalancer.tf code this is linked to the ec2 that is built through ec2.tf.

### Bastion - bastion_linux.tf

This uses its own set of variables which are in the bastion_linux.json code. Again this uses a module which will use the listed code in the build.

The json for this lists the IDs that will be given access to the bastion by providing the public key. Again this is stored in json so it is not recorded in terraform.

## Variables

### application_variables.json

This is where the majority of the variables in use will be stored. It includes a section for development, test, pre-production and production. Providing these options allows for changes to be made as the code progress through the stagess.

### locals.tf

Variables in this code are fairly standard across all environments. It does, however, include the code which points to application_variables.json (`app_variables = jsondecode(file("./application_variables.json"))`)

### data.tf

Contains many data sources that will be in used to lookup existing resources in AWS, they can then be referenced in Terraform.

### providers.tf

Again this is fairly standard across all environments.

### bastion_linux.tf

As mentioned above, this gives the ID details to allow access to bastion servers.
