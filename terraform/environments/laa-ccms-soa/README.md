# Service Runbook

_If you have any questions surrounding this page please post in the `#laa-appops` channel._

## Mandatory Information

### **Last review date:**

09/06/2025 - Andy Welsh. Service Redeployment

### **Description:**

CCMS-SOA (Service Orinted Architecture) acts as the service bus for CCMS. The application runs in an AWS ECS Cluster using manually configured, ECS-Optimised, EC2 Instances as it's underlying compute. These instances are provisioned via an Auto Scaling Group and deployed using a Launch Template and associated User Data boot script.

SOA operates in a client-server arrangement with a single *Admin Server* on it's own EC2 instance, running a single container and a variable number of *Enterprise Management Servers*, often referred to as simply *Managed Servers*. These managed servers may run across a variable amount of individual EC2 instances and a variable amount of containers, spread across these instances.

### **Databases:**

The application is backed by two RDS (Oracle) databases:

**SOA-DB:**

This is a custom DB used by Document Service SOA composite for caching documents before making calls to CCMS-EBS. The reason behind this is SOA is configured to retry in the event of any error while invoking EBS PL/SQL stored procedure to insert documents. Typical usage is when PUI and Apply applications submit documents to CCMS-EBS via SOA.

**TDS-DB:**

This database is essential for the SOA system to inject documents that are ultimately transmitted to NEC (Northgate). 
Previously, the database was tightly coupled with the SOA infrastructure. 
However, it has since been decoupled and is now managed under the ownership of the EDRMS application.

Given that EDRMS is the primary stakeholder of this database, EDRMS should ideally be deployed first. 
The database should be initialized using the scripts provided in the EDRMS environment. 
Additionally, the necessary configuration details—such as the JDBC URL, username, and password—should be stored in a secret, which can then be referenced by the SOA WebLogic cluster through its datasource binding.

### **Storage:**

Application state is held on an EFS storage volume, this is mounted to the ECS clusters EC2 Instances as part of their boot process and exposed to the running containers.

### Architecture Diagram

![SOA Architecture](docs/SOA-Infrastructure.png)

### **Service URLs:**

- **Administration Consle**: http://ccms-soa-admin.laa-ENVIRONMENT.modernisation-platform.service.justice.gov.uk:7001/console
- **EM (Enterprise Manager)**: http://ccms-soa-admin.laa-ENVIRONMENT.modernisation-platform.service.justice.gov.uk:7001/em
- **Composite Integrations**: http://ccms-soa-maanaged.laa-ENVIRONMENT.modernisation-platform.service.justice.gov.uk:8001

ENVIRONMENT values:
- development
- test
- preproduction
- production

### **Incident response hours:**

**TBC**

### **Incident contact details:**

laa-role-sre@digital.justice.gov.uk

### **Service team contact:**

laa-role-sre@digital.justice.gov.uk

### **Hosting environment:**

Modernisation Platform

### **Automatic alerts:**

**TBC**

### **Impact of an outage:**

**TBC**

### **Consumers of this service:**

- PUI
- Benefit Checker
- Apply Service
- Payment FTP Lambdas

### **Services consumed by this:**

- CCMS-EBS S3 (`laa-ccms-inbound-ENVIRONMENT-mp` and `laa-ccms-outbound-ENVIRONMENT-mp`)

### **Restrictions on access:**

Accessible from a [Shared Services AWS Workspace](https://dsdmoj.atlassian.net/wiki/spaces/aws/pages/4450288123/Self+Workspace+Creation+-+User+Guide) or other services within Mod Platform (MP):

- **Administration Console**: https://ccms-soa-admin.laa-$ENVIRONMENT.modernisation-platform.service.justice.gov.uk/console
- **EM (Enterprise Manager)**: https://ccms-soa-admin.laa-$ENVIRONMENT.modernisation-platform.service.justice.gov.uk/em

Exposed to other Mod Platform (MP) and Cloud Platform (CP) services. Available from Accessible from a [Shared Services AWS Workspace](https://dsdmoj.atlassian.net/wiki/spaces/aws/pages/4450288123/Self+Workspace+Creation+-+User+Guide) (for the purposes of integration testing):
- **Composite Integrations** (https://ccms-soa-admin.laa-$ENVIRONMENT.modernisation-platform.service.justice.gov.uk)

See the below table for which Workspace should be used for which Workspace should be used to access which environment:

| Environment   | Workspace |
|---------------|-----------|
| Development   | Non-Prod  |
| Test          | Prod      |
| Preproduction | Prod      |
| Production    | Prod      |

### **How to resolve specific issues:**

See [here](docs/KNOWN_ISSUES.md) for known issues and how to tackle them.

### **Service Restoration and New Environment Creation:**

See [here](docs/SERVICE_RESTORE.md) for an extensive breakdown of how to create a new environment or how to restore SOA in the event of disaster recovery.
