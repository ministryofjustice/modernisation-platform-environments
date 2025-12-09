# GitHub Copilot MCP Servers

This document covers the set up of MCP servers for use within [GitHub Copilot Chat](https://docs.github.com/en/copilot/how-tos/provide-context/use-mcp/extend-copilot-chat-with-mcp)

## Prerequisites

> If you're using the dev container in this repository, you can skip this section

- [Visual Studio Code](https://code.visualstudio.com/)

- [GitHub Copilot Chat](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot-chat) extension

- [AWS SSO CLI](https://github.com/synfinatic/aws-sso-cli)

  - You can find a ready-to-go configuration file at [ministryofjustice/.devcontainer](https://github.com/ministryofjustice/.devcontainer/blob/main/features/src/aws/src/home/vscode/.aws-sso/config.yaml)

- [GitHub CLI](https://cli.github.com/)

## Authenticate and Start

> [!WARNING]
> This documentation is experimental and is subject to any guidance published under [ministryofjustice/.github](https://github.com/ministryofjustice/.github/blob/main/docs/github-copilot-guidance.md).

1. Authenticate with AWS

   > This command may take several minutes to complete if you have access to a lot of AWS accounts.

   ```bash
   aws-sso login
   ```

1. Configure `~/.aws/config`

   ```bash
   aws-sso setup profiles --force
   ```

1. Authenticate with GitHub

    > If you're using a GitHub Codespace, you can skip this step.

    ```bash
    gh auth login --git-protocol ssh --skip-ssh-key --web
    ```

1. Start an MCP server
   - Open Extensions (Cmd/Ctrl + Shift + X).
   - Select the gear icon on the server you wish to start.
   - Select "Start Server".
     - If you're starting an AWS MCP server, you may be prompted for a profile. This profile will be in the format `${ACCOUNT_NAME}:${ROLE_NAME}`; for example, `cooker-development:ReadOnlyAccess`. Refer to `~/.aws/config` for a complete list.

## MCP Servers

| Server                                         | Documentation                                                              |
| ---------------------------------------------- | -------------------------------------------------------------------------- |
| `awslabs.aws-diagram-mcp-server`               | https://awslabs.github.io/mcp/servers/aws-diagram-mcp-server               |
| `awslabs.billing-cost-management-mcp-server`   | https://awslabs.github.io/mcp/servers/billing-cost-management-mcp-server   |
| `awslabs.cloudtrail-mcp-server`                | https://awslabs.github.io/mcp/servers/cloudtrail-mcp-server                |
| `awslabs.cloudwatch-mcp-server`                | https://awslabs.github.io/mcp/servers/cloudwatch-mcp-server                |
| `awslabs.cost-explorer-mcp-server`             | https://awslabs.github.io/mcp/servers/cost-explorer-mcp-server             |
| `awslabs.eks-mcp-server`                       | https://awslabs.github.io/mcp/servers/eks-mcp-server                       |
| `awslabs.iam-mcp-server`                       | https://awslabs.github.io/mcp/servers/iam-mcp-server                       |
| `awslabs.aws-pricing-mcp-server`               | https://awslabs.github.io/mcp/servers/aws-pricing-mcp-server               |
| `awslabs.terraform-mcp-server`                 | https://awslabs.github.io/mcp/servers/terraform-mcp-server                 |
| `awslabs.well-architected-security-mcp-server` | https://awslabs.github.io/mcp/servers/well-architected-security-mcp-server |
| `github`                                       | https://github.com/github/github-mcp-server                                |
| `hashicorp.terraform-mcp-server`               | https://developer.hashicorp.com/terraform/mcp-server                       |
