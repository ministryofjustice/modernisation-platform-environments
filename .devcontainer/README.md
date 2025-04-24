# Dev Container

> [!NOTE]
> This is a community supported feature

To assist with working on this repository, the community has configured a [dev container](https://containers.dev/) with the required tooling.

You can run this locally, or with [GitHub Codespaces](https://docs.github.com/en/codespaces/overview).

## Locally

> [!WARNING]  
> This has only been tested on macOS

### Prerequisites

- Docker

- Visual Studio Code

  - Dev Containers Extention

To launch locally, ensure the prerequisites are met, and then click the button below

[![Open in Dev Container](https://raw.githubusercontent.com/ministryofjustice/.devcontainer/refs/heads/main/contrib/badge.svg)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/ministryofjustice/modernisation-platform-environments)

## GitHub Codespaces

> [!IMPORTANT]  
> GitHub Codespaces are not currently paid for by the Ministry of Justice and are subject to the quotas [here](https://docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-codespaces/about-billing-for-github-codespaces#monthly-included-storage-and-core-hours-for-personal-accounts)

To launch a GitHub Codespace, click the button below

[![Open in Codespace](https://github.com/codespaces/badge.svg)](https://codespaces.new/ministryofjustice/modernisation-platform-environments)

## Tools

### AWS CLI

<https://aws.amazon.com/cli/>

### AWS SSO CLI

<https://synfinatic.github.io/aws-sso-cli/>

### Terraform

<https://www.terraform.io/>

### Trivy

<https://trivy.dev/>

### Checkov

<https://www.checkov.io/>

## Scripts

### `member-local-plan.sh`

This is a helper script for <https://user-guide.modernisation-platform.service.justice.gov.uk/user-guide/running-terraform-plan-locally.html#running-terraform-plan-locally>

Run it from within the environment folder, example:

```bash
cd terraform/environments/example

# Run wih default parameters
# stage=development
# role=modernisation-platform-developer
# apply=false
bash /workspaces/modernisation-platform-environments/scripts/member-local-plan.sh

# Run and override the role
# stage=development
# role=modernisation-platform-sandbox
# apply=false
bash /workspaces/modernisation-platform-environments/scripts/member-local-plan.sh -r modernisation-platform-sandbox

# Run and override the stage
# stage=test
# role=modernisation-platform-developer
# apply=false
bash /workspaces/modernisation-platform-environments/scripts/member-local-plan.sh -s test

# Run and apply (this will only work if you have sufficient permissions in your environments)
# stage=development
# role=platform-engineer-amdin
# apply=true
bash /workspaces/modernisation-platform-environments/scripts/member-local-plan.sh -r platform-engineer-amdin -a true
```

## Support

As this is a community supported feature, help is offered on a best endeavour basis.

If you do need help, please post in [`#devcontainer-community`](https://moj.enterprise.slack.com/archives/C06DZ4F04JZ)

## Contribution Guidelines

- If you wish to add a feature, check in with [`#devcontainer-community`](https://moj.enterprise.slack.com/archives/C06DZ4F04JZ) to see if its worth publishing centrally, otherwise

- Check that an existing feature doesn't cover what you're trying to add

- Where possible reuse the existing practices from other features, utilising the shared library `/usr/local/bin/devcontainer-utils`

## Maintainers

- [@ministryofjustice/devcontainer-community](https://github.com/orgs/ministryofjustice/teams/devcontainer-community)
