# GitHub Copilot MCP

> [!WARNING]
> This documentation is experimental

1. Authenticate

> [!NOTE]
> This may take a while if you have access to a lot of AWS accounts

    ```bash
    aws-sso login
    ```

1. Configure `~/.aws/config`

    ```bash
    aws-sso setup profiles --force
    ```