# Dev Container

> This is not a supported product of Modernisation Platform

To assist in the development of `modernisation-platform-environments`, the community have built a [dev container](https://containers.dev/) with the required tooling

## Prerequisites

- GitHub Codespaces

or

- Docker

- Visual Studio Code

  - Dev Containers Extention

## Running

### GitHub Codespaces

Launch from GitHub

### Locally

1. Ensure prerequisites are met

1. Clone repository

1. Open repository in Visual Studio Code

1. Reopen in container

## Tools

### AWS CLI

<https://aws.amazon.com/cli/>

### AWS SSO CLI

<https://synfinatic.github.io/aws-sso-cli/>

### Terraform Switcher

<https://tfswitch.warrensbox.com/>

## Scripts

### `member-local-plan.sh`

This is a helper script for <https://user-guide.modernisation-platform.service.justice.gov.uk/user-guide/running-terraform-plan-locally.html#running-terraform-plan-locally>

Run it from within the environment folder, example:

```bash
cd terraform/environments/example

# Run wih default parameters
# stage=development
# role=modernisation-platform-developer
bash ../../../scripts/member-local-plan.sh

# Run and override a parameter
# stage=development
# role=modernisation-platform-sandbox
bash ../../../scripts/member-local-plan.sh -r modernisation-platform-sandbox
```

## Maintainers

- [@jacobwoffenden](https://github.com/jacobwoffenden)
