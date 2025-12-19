# GitHub Copilot Agents

This document covers the set up of Copilot agents for use within [GitHub Copilot Chat](https://code.visualstudio.com/docs/copilot/customization/custom-agents).

> [!WARNING]
> These agents are community contributions and are **not officially supported** by the Modernisation Platform team. They are provided as-is and may change or be removed without notice. Use at your own discretion.

## Prerequisites

> If you're using the dev container in this repository, you can skip this section

- [Visual Studio Code](https://code.visualstudio.com/)

- [GitHub Copilot Chat](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot-chat) extension

- Agent mode enabled in Copilot Chat settings

## Using Agents

Agents are located in `.github/agents/` and provide task-specific automation capabilities within Copilot Chat.

To use an agent:

1. Open Copilot Chat (Cmd/Ctrl + Shift + I)

1. Select the agent from the mode picker (where `Agent`, `Edit`, and `Ask` appear)

1. Enter your prompt describing the task

## Available Agents

| Agent                   | Location                                        |
| ----------------------- | ----------------------------------------------- |
| `terraform-maintenance` | `.github/agents/terraform-maintenance.agent.md` |

Refer to each agent's file for detailed instructions and capabilities.

## Support

Agents are community contributions. The Modernisation Platform team does not provide support or accept feature requests for agents.