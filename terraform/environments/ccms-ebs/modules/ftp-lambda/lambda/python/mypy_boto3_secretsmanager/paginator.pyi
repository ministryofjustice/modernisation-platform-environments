"""
Type annotations for secretsmanager service client paginators.

[Documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/paginators/)

Copyright 2025 Vlad Emelianov

Usage::

    ```python
    from boto3.session import Session

    from mypy_boto3_secretsmanager.client import SecretsManagerClient
    from mypy_boto3_secretsmanager.paginator import (
        ListSecretsPaginator,
    )

    session = Session()
    client: SecretsManagerClient = session.client("secretsmanager")

    list_secrets_paginator: ListSecretsPaginator = client.get_paginator("list_secrets")
    ```
"""

from __future__ import annotations

import sys
from typing import TYPE_CHECKING

from botocore.paginate import PageIterator, Paginator

from .type_defs import ListSecretsRequestPaginateTypeDef, ListSecretsResponseTypeDef

if sys.version_info >= (3, 12):
    from typing import Unpack
else:
    from typing_extensions import Unpack

__all__ = ("ListSecretsPaginator",)

if TYPE_CHECKING:
    _ListSecretsPaginatorBase = Paginator[ListSecretsResponseTypeDef]
else:
    _ListSecretsPaginatorBase = Paginator  # type: ignore[assignment]

class ListSecretsPaginator(_ListSecretsPaginatorBase):
    """
    [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/paginator/ListSecrets.html#SecretsManager.Paginator.ListSecrets)
    [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/paginators/#listsecretspaginator)
    """
    def paginate(  # type: ignore[override]
        self, **kwargs: Unpack[ListSecretsRequestPaginateTypeDef]
    ) -> PageIterator[ListSecretsResponseTypeDef]:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/paginator/ListSecrets.html#SecretsManager.Paginator.ListSecrets.paginate)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/paginators/#listsecretspaginator)
        """
