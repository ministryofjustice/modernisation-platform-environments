# Modernisation Platform Environments

[![Standards Icon]][Standards Link] [![Format Code Icon]][Format Code Link] [![Scorecards Icon]][Scorecards Link] [![SCA Icon]][SCA Link] [![Terraform SCA Icon]][Terraform SCA Link]

## Introduction

This repository contains the Modernisation Platform infrastructure and workflow for user environments (AWS accounts).

Here you can add infrastructure to your environment with [Terraform](https://www.terraform.io/). The terraform is then applied using github workflows, each environment having its own workflow.

To learn more about how the Modernisation Platform works, please see our main repo [modernisation-platform](https://github.com/ministryofjustice/modernisation-platform), or our [user guidance](https://ministryofjustice.github.io/modernisation-platform)

To request an environment, a new feature, or to report a bug, please [create an issue](https://github.com/ministryofjustice/modernisation-platform/issues/new/choose) on our main repo using the relevant issue template.

[Standards Link]: https://github-community.service.justice.gov.uk/repository-standards/modernisation-platform-environments "Repo standards badge."
[Standards Icon]: https://github-community.service.justice.gov.uk/repository-standards/api/modernisation-platform-environments/badge
[Format Code Icon]: https://img.shields.io/github/actions/workflow/status/ministryofjustice/modernisation-platform-environments/format-code.yml?labelColor=231f20&style=for-the-badge&label=Formate%20Code
[Format Code Link]: https://github.com/ministryofjustice/modernisation-platform-environments/actions/workflows/format-code.yml
[Scorecards Icon]: https://img.shields.io/github/actions/workflow/status/ministryofjustice/modernisation-platform-environments/scorecards.yml?branch=main&labelColor=231f20&style=for-the-badge&label=Scorecards
[Scorecards Link]: https://github.com/ministryofjustice/modernisation-platform-environments/actions/workflows/scorecards.yml
[SCA Icon]: https://img.shields.io/github/actions/workflow/status/ministryofjustice/modernisation-platform-environments/code-scanning.yml?branch=main&labelColor=231f20&style=for-the-badge&label=Secure%20Code%20Analysis
[SCA Link]: https://github.com/ministryofjustice/modernisation-platform-environments/actions/workflows/code-scanning.yml
[Terraform SCA Icon]: https://img.shields.io/github/actions/workflow/status/ministryofjustice/modernisation-platform-environments/code-scanning.yml?branch=main&labelColor=231f20&style=for-the-badge&label=Terraform%20Static%20Code%20Analysis
[Terraform SCA Link]: https://github.com/ministryofjustice/modernisation-platform-environments/actions/workflows/terraform-static-analysis.yml
