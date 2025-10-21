# GitHub Copilot MCP

> [!WARNING]
> This documentation is experimental and is subject to any guidance published under [ministryofjustice/.github](https://github.com/ministryofjustice/.github/blob/main/docs/github-copilot-guidance.md).

1. Authenticate

   > [!NOTE]
   > This command may take several minutes to complete if you have access to a lot of AWS accounts.

    ```bash
    aws-sso login
    ```

1. Configure `~/.aws/config`

    ```bash
    aws-sso setup profiles --force
    ```

1. Start an MCP server

  - Open Extensions (Command + Shift + X).
  - Select the gear icon on the server you wish to start.
  - Select "Start Server".
    - If you're starting an AWS MCP server, you may be prompted for a profile. This profile will be in the format `${ACCOUNT_NAME}:${ROLE_NAME}`; for example, `cooker-development:ReadOnlyAccess`. Refer to `~/.aws/config` for a complete list.