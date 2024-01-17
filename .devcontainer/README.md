# Dev Container

> This is a community supported feature

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
bash ../../../scripts/member-local-plan.sh

# Run and override a parameter
# stage=development
# role=modernisation-platform-sandbox
bash ../../../scripts/member-local-plan.sh -r modernisation-platform-sandbox
```

## Support

As this is a community supported feature, help is offered on a best endeavour basis.

If you do need help, please post in [`#devcontainer`](https://moj.enterprise.slack.com/archives/C06DZ4F04JZ)

## Contribution Guidelines

- Check that an existing feature doesn't cover what you're trying to add

- Where possible reuse the existing practices from other features, utilising the shared library `devcontainer-utils`

- If you are creating a feature, add it to the feature testing matrix in the GitHub Actions workflow and ensure appropiate tests exist

## Maintainers

- [@jacobwoffenden](https://github.com/jacobwoffenden)

- [@Gary-H9](https://github.com/Gary-H9)
