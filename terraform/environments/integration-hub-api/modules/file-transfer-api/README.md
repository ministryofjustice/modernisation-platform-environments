# File transfer API component module

New-account recovery module used only by `../../file-transfer-api`. It starts from
the existing API module, preserving the upload contract and resource names while
using the new incoming bucket, prefix-scoped permissions and exact component OIDC
trust. Legacy state moves are deliberately omitted: the replacement uses fresh state.
See the component README for rollout order and operational validation.
