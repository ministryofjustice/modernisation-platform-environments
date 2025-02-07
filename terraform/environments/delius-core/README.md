# Service Runbook

  

<!-- This is a template that should be populated by the development team when moving to the modernisation platform, but also reviewed and kept up to date.

To ensure that people looking at your runbook can get the information they need quickly, your runbook should be short but clear. Throughout, only use acronyms if you’re confident that someone who has just been woken up at 3am would understand them. -->

  

_If you have any questions surrounding this page please post in the `#ask-probation-hosting` channel._

  

## Mandatory Information

  

### **Last review date:**

  17/12/24

<!-- Adding the last date this page was reviewed, with any accompanying information -->

  

### **Description:**
This directory contains the Terraform configuration for the Delius Core environments, which are primarily comprised of the following resources:

* WebLogic app ECS
* WebLogic EIS ECS
  * external interface services
  * serves API endpoints to allow services to interact with Delius data
* LDAP ECS
  * used for authenticating users in Delius, MIS, User Management, PWM, and apps in Cloud Platform
* Password manager (PWM) ECS
* Oracle EC2 databases
  * used by Weblogic, GDPR (now in CP)
* Alfresco EFS + SFS
  * Alfresco is mainly hosted in Cloud Platform but some resources remain in MP


<!-- A short (less than 50 word) description of what your service does, and who it’s for.-->

  

### **Service URLs:**

* WebLogic
  * Base URL is [https://ndelius.[env].delius-core.[vpc].modernisation-platform.service.justice.gov.uk](https://ndelius.dev.delius-core.hmpps-development.modernisation-platform.service.justice.gov.uk/NDelius-war/delius/JSP/auth/login.xhtml)
  * NB: This needs a trailing path of either /jspellhtml/_OR /NDelius_ to hit the target group, e.g. `/NDelius-war/delius/JSP/auth/login.xhtml`
  * Also, ensure you are connected to the GlobalProtect VPN
* LDAP
  * ldaps://ldap.[env].delius-core.[vpc].modernisation-platform.service.justice.gov.uk:636
* PWM
  * [https://pwm.[env].delius-core.[vpc].modernisation-platform.service.justice.gov.uk/public/forgottenpassword](https://pwm.dev.delius-core.hmpps-development.modernisation-platform.service.justice.gov.uk/public/forgottenpassword)

Replace [env] and [vpc] with the following values:

| [env] |    [vpc]   |
|-------|--------------------|
|dev    | hmpps-development  |
|test   | hmpps-test         |
|stage  | hmpps-preproduction|
|preprod| hmpps-preproduction|

<!-- The URL(s) of the service’s production environment, and test environments if possible-->



### **Hosting environment:**

  

Modernisation Platform

  

<!-- If your service is hosted on another MOJ team’s infrastructure, link to their runbook. If your service has another arrangement or runs its own infrastructure, you should list the supplier of that infrastructure (ideally linking to your account’s login page) and describe, simply and briefly, how to raise an issue with them. -->

### Structure

Most of the configuration for the environments is handled in the base level of the delius-core directory, where we have `main_[environment].tf` files that call the `delius_environment`module, passing in locals defined in `locals_[environment].tf` files.

The bulk of the resources are defined in a modular structure where there is a `delius_environment` module that will call other reusable modules such as the `delius_microservice` module or the `oracle_db_instance` module, with files for each microservice deployment (e.g. `weblogic.tf` which is only calling the `delius_microservice` module, or `database.tf` that primarily contains calls to the `oracle_db_instance` module).
