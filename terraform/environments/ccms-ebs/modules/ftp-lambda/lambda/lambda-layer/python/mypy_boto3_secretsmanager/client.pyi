"""
Type annotations for secretsmanager service Client.

[Documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/)

Copyright 2025 Vlad Emelianov

Usage::

    ```python
    from boto3.session import Session
    from mypy_boto3_secretsmanager.client import SecretsManagerClient

    session = Session()
    client: SecretsManagerClient = session.client("secretsmanager")
    ```
"""

from __future__ import annotations

import sys
from typing import Any

from botocore.client import BaseClient, ClientMeta
from botocore.errorfactory import BaseClientExceptions
from botocore.exceptions import ClientError as BotocoreClientError

from .paginator import ListSecretsPaginator
from .type_defs import (
    BatchGetSecretValueRequestTypeDef,
    BatchGetSecretValueResponseTypeDef,
    CancelRotateSecretRequestTypeDef,
    CancelRotateSecretResponseTypeDef,
    CreateSecretRequestTypeDef,
    CreateSecretResponseTypeDef,
    DeleteResourcePolicyRequestTypeDef,
    DeleteResourcePolicyResponseTypeDef,
    DeleteSecretRequestTypeDef,
    DeleteSecretResponseTypeDef,
    DescribeSecretRequestTypeDef,
    DescribeSecretResponseTypeDef,
    EmptyResponseMetadataTypeDef,
    GetRandomPasswordRequestTypeDef,
    GetRandomPasswordResponseTypeDef,
    GetResourcePolicyRequestTypeDef,
    GetResourcePolicyResponseTypeDef,
    GetSecretValueRequestTypeDef,
    GetSecretValueResponseTypeDef,
    ListSecretsRequestTypeDef,
    ListSecretsResponseTypeDef,
    ListSecretVersionIdsRequestTypeDef,
    ListSecretVersionIdsResponseTypeDef,
    PutResourcePolicyRequestTypeDef,
    PutResourcePolicyResponseTypeDef,
    PutSecretValueRequestTypeDef,
    PutSecretValueResponseTypeDef,
    RemoveRegionsFromReplicationRequestTypeDef,
    RemoveRegionsFromReplicationResponseTypeDef,
    ReplicateSecretToRegionsRequestTypeDef,
    ReplicateSecretToRegionsResponseTypeDef,
    RestoreSecretRequestTypeDef,
    RestoreSecretResponseTypeDef,
    RotateSecretRequestTypeDef,
    RotateSecretResponseTypeDef,
    StopReplicationToReplicaRequestTypeDef,
    StopReplicationToReplicaResponseTypeDef,
    TagResourceRequestTypeDef,
    UntagResourceRequestTypeDef,
    UpdateSecretRequestTypeDef,
    UpdateSecretResponseTypeDef,
    UpdateSecretVersionStageRequestTypeDef,
    UpdateSecretVersionStageResponseTypeDef,
    ValidateResourcePolicyRequestTypeDef,
    ValidateResourcePolicyResponseTypeDef,
)

if sys.version_info >= (3, 9):
    from builtins import type as Type
    from collections.abc import Mapping
else:
    from typing import Mapping, Type
if sys.version_info >= (3, 12):
    from typing import Literal, Unpack
else:
    from typing_extensions import Literal, Unpack

__all__ = ("SecretsManagerClient",)

class Exceptions(BaseClientExceptions):
    ClientError: Type[BotocoreClientError]
    DecryptionFailure: Type[BotocoreClientError]
    EncryptionFailure: Type[BotocoreClientError]
    InternalServiceError: Type[BotocoreClientError]
    InvalidNextTokenException: Type[BotocoreClientError]
    InvalidParameterException: Type[BotocoreClientError]
    InvalidRequestException: Type[BotocoreClientError]
    LimitExceededException: Type[BotocoreClientError]
    MalformedPolicyDocumentException: Type[BotocoreClientError]
    PreconditionNotMetException: Type[BotocoreClientError]
    PublicPolicyException: Type[BotocoreClientError]
    ResourceExistsException: Type[BotocoreClientError]
    ResourceNotFoundException: Type[BotocoreClientError]

class SecretsManagerClient(BaseClient):
    """
    [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager.html#SecretsManager.Client)
    [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/)
    """

    meta: ClientMeta

    @property
    def exceptions(self) -> Exceptions:
        """
        SecretsManagerClient exceptions.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager.html#SecretsManager.Client)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#exceptions)
        """

    def can_paginate(self, operation_name: str) -> bool:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/can_paginate.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#can_paginate)
        """

    def generate_presigned_url(
        self,
        ClientMethod: str,
        Params: Mapping[str, Any] = ...,
        ExpiresIn: int = 3600,
        HttpMethod: str = ...,
    ) -> str:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/generate_presigned_url.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#generate_presigned_url)
        """

    def batch_get_secret_value(
        self, **kwargs: Unpack[BatchGetSecretValueRequestTypeDef]
    ) -> BatchGetSecretValueResponseTypeDef:
        """
        Retrieves the contents of the encrypted fields <code>SecretString</code> or
        <code>SecretBinary</code> for up to 20 secrets.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/batch_get_secret_value.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#batch_get_secret_value)
        """

    def cancel_rotate_secret(
        self, **kwargs: Unpack[CancelRotateSecretRequestTypeDef]
    ) -> CancelRotateSecretResponseTypeDef:
        """
        Turns off automatic rotation, and if a rotation is currently in progress,
        cancels the rotation.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/cancel_rotate_secret.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#cancel_rotate_secret)
        """

    def create_secret(
        self, **kwargs: Unpack[CreateSecretRequestTypeDef]
    ) -> CreateSecretResponseTypeDef:
        """
        Creates a new secret.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/create_secret.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#create_secret)
        """

    def delete_resource_policy(
        self, **kwargs: Unpack[DeleteResourcePolicyRequestTypeDef]
    ) -> DeleteResourcePolicyResponseTypeDef:
        """
        Deletes the resource-based permission policy attached to the secret.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/delete_resource_policy.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#delete_resource_policy)
        """

    def delete_secret(
        self, **kwargs: Unpack[DeleteSecretRequestTypeDef]
    ) -> DeleteSecretResponseTypeDef:
        """
        Deletes a secret and all of its versions.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/delete_secret.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#delete_secret)
        """

    def describe_secret(
        self, **kwargs: Unpack[DescribeSecretRequestTypeDef]
    ) -> DescribeSecretResponseTypeDef:
        """
        Retrieves the details of a secret.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/describe_secret.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#describe_secret)
        """

    def get_random_password(
        self, **kwargs: Unpack[GetRandomPasswordRequestTypeDef]
    ) -> GetRandomPasswordResponseTypeDef:
        """
        Generates a random password.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/get_random_password.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#get_random_password)
        """

    def get_resource_policy(
        self, **kwargs: Unpack[GetResourcePolicyRequestTypeDef]
    ) -> GetResourcePolicyResponseTypeDef:
        """
        Retrieves the JSON text of the resource-based policy document attached to the
        secret.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/get_resource_policy.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#get_resource_policy)
        """

    def get_secret_value(
        self, **kwargs: Unpack[GetSecretValueRequestTypeDef]
    ) -> GetSecretValueResponseTypeDef:
        """
        Retrieves the contents of the encrypted fields <code>SecretString</code> or
        <code>SecretBinary</code> from the specified version of a secret, whichever
        contains content.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/get_secret_value.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#get_secret_value)
        """

    def list_secret_version_ids(
        self, **kwargs: Unpack[ListSecretVersionIdsRequestTypeDef]
    ) -> ListSecretVersionIdsResponseTypeDef:
        """
        Lists the versions of a secret.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/list_secret_version_ids.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#list_secret_version_ids)
        """

    def list_secrets(
        self, **kwargs: Unpack[ListSecretsRequestTypeDef]
    ) -> ListSecretsResponseTypeDef:
        """
        Lists the secrets that are stored by Secrets Manager in the Amazon Web Services
        account, not including secrets that are marked for deletion.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/list_secrets.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#list_secrets)
        """

    def put_resource_policy(
        self, **kwargs: Unpack[PutResourcePolicyRequestTypeDef]
    ) -> PutResourcePolicyResponseTypeDef:
        """
        Attaches a resource-based permission policy to a secret.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/put_resource_policy.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#put_resource_policy)
        """

    def put_secret_value(
        self, **kwargs: Unpack[PutSecretValueRequestTypeDef]
    ) -> PutSecretValueResponseTypeDef:
        """
        Creates a new version with a new encrypted secret value and attaches it to the
        secret.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/put_secret_value.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#put_secret_value)
        """

    def remove_regions_from_replication(
        self, **kwargs: Unpack[RemoveRegionsFromReplicationRequestTypeDef]
    ) -> RemoveRegionsFromReplicationResponseTypeDef:
        """
        For a secret that is replicated to other Regions, deletes the secret replicas
        from the Regions you specify.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/remove_regions_from_replication.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#remove_regions_from_replication)
        """

    def replicate_secret_to_regions(
        self, **kwargs: Unpack[ReplicateSecretToRegionsRequestTypeDef]
    ) -> ReplicateSecretToRegionsResponseTypeDef:
        """
        Replicates the secret to a new Regions.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/replicate_secret_to_regions.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#replicate_secret_to_regions)
        """

    def restore_secret(
        self, **kwargs: Unpack[RestoreSecretRequestTypeDef]
    ) -> RestoreSecretResponseTypeDef:
        """
        Cancels the scheduled deletion of a secret by removing the
        <code>DeletedDate</code> time stamp.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/restore_secret.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#restore_secret)
        """

    def rotate_secret(
        self, **kwargs: Unpack[RotateSecretRequestTypeDef]
    ) -> RotateSecretResponseTypeDef:
        """
        Configures and starts the asynchronous process of rotating the secret.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/rotate_secret.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#rotate_secret)
        """

    def stop_replication_to_replica(
        self, **kwargs: Unpack[StopReplicationToReplicaRequestTypeDef]
    ) -> StopReplicationToReplicaResponseTypeDef:
        """
        Removes the link between the replica secret and the primary secret and promotes
        the replica to a primary secret in the replica Region.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/stop_replication_to_replica.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#stop_replication_to_replica)
        """

    def tag_resource(
        self, **kwargs: Unpack[TagResourceRequestTypeDef]
    ) -> EmptyResponseMetadataTypeDef:
        """
        Attaches tags to a secret.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/tag_resource.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#tag_resource)
        """

    def untag_resource(
        self, **kwargs: Unpack[UntagResourceRequestTypeDef]
    ) -> EmptyResponseMetadataTypeDef:
        """
        Removes specific tags from a secret.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/untag_resource.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#untag_resource)
        """

    def update_secret(
        self, **kwargs: Unpack[UpdateSecretRequestTypeDef]
    ) -> UpdateSecretResponseTypeDef:
        """
        Modifies the details of a secret, including metadata and the secret value.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/update_secret.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#update_secret)
        """

    def update_secret_version_stage(
        self, **kwargs: Unpack[UpdateSecretVersionStageRequestTypeDef]
    ) -> UpdateSecretVersionStageResponseTypeDef:
        """
        Modifies the staging labels attached to a version of a secret.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/update_secret_version_stage.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#update_secret_version_stage)
        """

    def validate_resource_policy(
        self, **kwargs: Unpack[ValidateResourcePolicyRequestTypeDef]
    ) -> ValidateResourcePolicyResponseTypeDef:
        """
        Validates that a resource policy does not grant a wide range of principals
        access to your secret.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/validate_resource_policy.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#validate_resource_policy)
        """

    def get_paginator(  # type: ignore[override]
        self, operation_name: Literal["list_secrets"]
    ) -> ListSecretsPaginator:
        """
        Create a paginator for an operation.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/get_paginator.html)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/client/#get_paginator)
        """
