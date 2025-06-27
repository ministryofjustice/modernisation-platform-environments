"""
Main interface for secretsmanager service.

[Documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/)

Copyright 2025 Vlad Emelianov

Usage::

    ```python
    from boto3.session import Session
    from mypy_boto3_secretsmanager import (
        Client,
        ListSecretsPaginator,
        SecretsManagerClient,
    )

    session = Session()
    client: SecretsManagerClient = session.client("secretsmanager")

    list_secrets_paginator: ListSecretsPaginator = client.get_paginator("list_secrets")
    ```
"""

from .client import SecretsManagerClient
from .paginator import ListSecretsPaginator

Client = SecretsManagerClient


__all__ = ("Client", "ListSecretsPaginator", "SecretsManagerClient")
