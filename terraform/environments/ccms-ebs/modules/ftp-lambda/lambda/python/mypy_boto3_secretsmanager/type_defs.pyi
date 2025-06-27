"""
Type annotations for secretsmanager service type definitions.

[Documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_secretsmanager/type_defs/)

Copyright 2025 Vlad Emelianov

Usage::

    ```python
    from mypy_boto3_secretsmanager.type_defs import APIErrorTypeTypeDef

    data: APIErrorTypeTypeDef = ...
    ```
"""

from __future__ import annotations

import sys
from datetime import datetime
from typing import IO, Any, Union

from botocore.response import StreamingBody

from .literals import FilterNameStringTypeType, SortOrderTypeType, StatusTypeType

if sys.version_info >= (3, 9):
    from builtins import dict as Dict
    from builtins import list as List
    from collections.abc import Sequence
else:
    from typing import Dict, List, Sequence
if sys.version_info >= (3, 12):
    from typing import NotRequired, TypedDict
else:
    from typing_extensions import NotRequired, TypedDict

__all__ = (
    "APIErrorTypeTypeDef",
    "BatchGetSecretValueRequestTypeDef",
    "BatchGetSecretValueResponseTypeDef",
    "BlobTypeDef",
    "CancelRotateSecretRequestTypeDef",
    "CancelRotateSecretResponseTypeDef",
    "CreateSecretRequestTypeDef",
    "CreateSecretResponseTypeDef",
    "DeleteResourcePolicyRequestTypeDef",
    "DeleteResourcePolicyResponseTypeDef",
    "DeleteSecretRequestTypeDef",
    "DeleteSecretResponseTypeDef",
    "DescribeSecretRequestTypeDef",
    "DescribeSecretResponseTypeDef",
    "EmptyResponseMetadataTypeDef",
    "FilterTypeDef",
    "GetRandomPasswordRequestTypeDef",
    "GetRandomPasswordResponseTypeDef",
    "GetResourcePolicyRequestTypeDef",
    "GetResourcePolicyResponseTypeDef",
    "GetSecretValueRequestTypeDef",
    "GetSecretValueResponseTypeDef",
    "ListSecretVersionIdsRequestTypeDef",
    "ListSecretVersionIdsResponseTypeDef",
    "ListSecretsRequestPaginateTypeDef",
    "ListSecretsRequestTypeDef",
    "ListSecretsResponseTypeDef",
    "PaginatorConfigTypeDef",
    "PutResourcePolicyRequestTypeDef",
    "PutResourcePolicyResponseTypeDef",
    "PutSecretValueRequestTypeDef",
    "PutSecretValueResponseTypeDef",
    "RemoveRegionsFromReplicationRequestTypeDef",
    "RemoveRegionsFromReplicationResponseTypeDef",
    "ReplicaRegionTypeTypeDef",
    "ReplicateSecretToRegionsRequestTypeDef",
    "ReplicateSecretToRegionsResponseTypeDef",
    "ReplicationStatusTypeTypeDef",
    "ResponseMetadataTypeDef",
    "RestoreSecretRequestTypeDef",
    "RestoreSecretResponseTypeDef",
    "RotateSecretRequestTypeDef",
    "RotateSecretResponseTypeDef",
    "RotationRulesTypeTypeDef",
    "SecretListEntryTypeDef",
    "SecretValueEntryTypeDef",
    "SecretVersionsListEntryTypeDef",
    "StopReplicationToReplicaRequestTypeDef",
    "StopReplicationToReplicaResponseTypeDef",
    "TagResourceRequestTypeDef",
    "TagTypeDef",
    "UntagResourceRequestTypeDef",
    "UpdateSecretRequestTypeDef",
    "UpdateSecretResponseTypeDef",
    "UpdateSecretVersionStageRequestTypeDef",
    "UpdateSecretVersionStageResponseTypeDef",
    "ValidateResourcePolicyRequestTypeDef",
    "ValidateResourcePolicyResponseTypeDef",
    "ValidationErrorsEntryTypeDef",
)

class APIErrorTypeTypeDef(TypedDict):
    SecretId: NotRequired[str]
    ErrorCode: NotRequired[str]
    Message: NotRequired[str]

class FilterTypeDef(TypedDict):
    Key: NotRequired[FilterNameStringTypeType]
    Values: NotRequired[Sequence[str]]

class ResponseMetadataTypeDef(TypedDict):
    RequestId: str
    HTTPStatusCode: int
    HTTPHeaders: Dict[str, str]
    RetryAttempts: int
    HostId: NotRequired[str]

class SecretValueEntryTypeDef(TypedDict):
    ARN: NotRequired[str]
    Name: NotRequired[str]
    VersionId: NotRequired[str]
    SecretBinary: NotRequired[bytes]
    SecretString: NotRequired[str]
    VersionStages: NotRequired[List[str]]
    CreatedDate: NotRequired[datetime]

BlobTypeDef = Union[str, bytes, IO[Any], StreamingBody]

class CancelRotateSecretRequestTypeDef(TypedDict):
    SecretId: str

class ReplicaRegionTypeTypeDef(TypedDict):
    Region: NotRequired[str]
    KmsKeyId: NotRequired[str]

class TagTypeDef(TypedDict):
    Key: NotRequired[str]
    Value: NotRequired[str]

class ReplicationStatusTypeTypeDef(TypedDict):
    Region: NotRequired[str]
    KmsKeyId: NotRequired[str]
    Status: NotRequired[StatusTypeType]
    StatusMessage: NotRequired[str]
    LastAccessedDate: NotRequired[datetime]

class DeleteResourcePolicyRequestTypeDef(TypedDict):
    SecretId: str

class DeleteSecretRequestTypeDef(TypedDict):
    SecretId: str
    RecoveryWindowInDays: NotRequired[int]
    ForceDeleteWithoutRecovery: NotRequired[bool]

class DescribeSecretRequestTypeDef(TypedDict):
    SecretId: str

class RotationRulesTypeTypeDef(TypedDict):
    AutomaticallyAfterDays: NotRequired[int]
    Duration: NotRequired[str]
    ScheduleExpression: NotRequired[str]

class GetRandomPasswordRequestTypeDef(TypedDict):
    PasswordLength: NotRequired[int]
    ExcludeCharacters: NotRequired[str]
    ExcludeNumbers: NotRequired[bool]
    ExcludePunctuation: NotRequired[bool]
    ExcludeUppercase: NotRequired[bool]
    ExcludeLowercase: NotRequired[bool]
    IncludeSpace: NotRequired[bool]
    RequireEachIncludedType: NotRequired[bool]

class GetResourcePolicyRequestTypeDef(TypedDict):
    SecretId: str

class GetSecretValueRequestTypeDef(TypedDict):
    SecretId: str
    VersionId: NotRequired[str]
    VersionStage: NotRequired[str]

class ListSecretVersionIdsRequestTypeDef(TypedDict):
    SecretId: str
    MaxResults: NotRequired[int]
    NextToken: NotRequired[str]
    IncludeDeprecated: NotRequired[bool]

class SecretVersionsListEntryTypeDef(TypedDict):
    VersionId: NotRequired[str]
    VersionStages: NotRequired[List[str]]
    LastAccessedDate: NotRequired[datetime]
    CreatedDate: NotRequired[datetime]
    KmsKeyIds: NotRequired[List[str]]

class PaginatorConfigTypeDef(TypedDict):
    MaxItems: NotRequired[int]
    PageSize: NotRequired[int]
    StartingToken: NotRequired[str]

class PutResourcePolicyRequestTypeDef(TypedDict):
    SecretId: str
    ResourcePolicy: str
    BlockPublicPolicy: NotRequired[bool]

class RemoveRegionsFromReplicationRequestTypeDef(TypedDict):
    SecretId: str
    RemoveReplicaRegions: Sequence[str]

class RestoreSecretRequestTypeDef(TypedDict):
    SecretId: str

class StopReplicationToReplicaRequestTypeDef(TypedDict):
    SecretId: str

class UntagResourceRequestTypeDef(TypedDict):
    SecretId: str
    TagKeys: Sequence[str]

class UpdateSecretVersionStageRequestTypeDef(TypedDict):
    SecretId: str
    VersionStage: str
    RemoveFromVersionId: NotRequired[str]
    MoveToVersionId: NotRequired[str]

class ValidateResourcePolicyRequestTypeDef(TypedDict):
    ResourcePolicy: str
    SecretId: NotRequired[str]

class ValidationErrorsEntryTypeDef(TypedDict):
    CheckName: NotRequired[str]
    ErrorMessage: NotRequired[str]

class BatchGetSecretValueRequestTypeDef(TypedDict):
    SecretIdList: NotRequired[Sequence[str]]
    Filters: NotRequired[Sequence[FilterTypeDef]]
    MaxResults: NotRequired[int]
    NextToken: NotRequired[str]

class ListSecretsRequestTypeDef(TypedDict):
    IncludePlannedDeletion: NotRequired[bool]
    MaxResults: NotRequired[int]
    NextToken: NotRequired[str]
    Filters: NotRequired[Sequence[FilterTypeDef]]
    SortOrder: NotRequired[SortOrderTypeType]

class CancelRotateSecretResponseTypeDef(TypedDict):
    ARN: str
    Name: str
    VersionId: str
    ResponseMetadata: ResponseMetadataTypeDef

class DeleteResourcePolicyResponseTypeDef(TypedDict):
    ARN: str
    Name: str
    ResponseMetadata: ResponseMetadataTypeDef

class DeleteSecretResponseTypeDef(TypedDict):
    ARN: str
    Name: str
    DeletionDate: datetime
    ResponseMetadata: ResponseMetadataTypeDef

class EmptyResponseMetadataTypeDef(TypedDict):
    ResponseMetadata: ResponseMetadataTypeDef

class GetRandomPasswordResponseTypeDef(TypedDict):
    RandomPassword: str
    ResponseMetadata: ResponseMetadataTypeDef

class GetResourcePolicyResponseTypeDef(TypedDict):
    ARN: str
    Name: str
    ResourcePolicy: str
    ResponseMetadata: ResponseMetadataTypeDef

class GetSecretValueResponseTypeDef(TypedDict):
    ARN: str
    Name: str
    VersionId: str
    SecretBinary: bytes
    SecretString: str
    VersionStages: List[str]
    CreatedDate: datetime
    ResponseMetadata: ResponseMetadataTypeDef

class PutResourcePolicyResponseTypeDef(TypedDict):
    ARN: str
    Name: str
    ResponseMetadata: ResponseMetadataTypeDef

class PutSecretValueResponseTypeDef(TypedDict):
    ARN: str
    Name: str
    VersionId: str
    VersionStages: List[str]
    ResponseMetadata: ResponseMetadataTypeDef

class RestoreSecretResponseTypeDef(TypedDict):
    ARN: str
    Name: str
    ResponseMetadata: ResponseMetadataTypeDef

class RotateSecretResponseTypeDef(TypedDict):
    ARN: str
    Name: str
    VersionId: str
    ResponseMetadata: ResponseMetadataTypeDef

class StopReplicationToReplicaResponseTypeDef(TypedDict):
    ARN: str
    ResponseMetadata: ResponseMetadataTypeDef

class UpdateSecretResponseTypeDef(TypedDict):
    ARN: str
    Name: str
    VersionId: str
    ResponseMetadata: ResponseMetadataTypeDef

class UpdateSecretVersionStageResponseTypeDef(TypedDict):
    ARN: str
    Name: str
    ResponseMetadata: ResponseMetadataTypeDef

class BatchGetSecretValueResponseTypeDef(TypedDict):
    SecretValues: List[SecretValueEntryTypeDef]
    Errors: List[APIErrorTypeTypeDef]
    ResponseMetadata: ResponseMetadataTypeDef
    NextToken: NotRequired[str]

class PutSecretValueRequestTypeDef(TypedDict):
    SecretId: str
    ClientRequestToken: NotRequired[str]
    SecretBinary: NotRequired[BlobTypeDef]
    SecretString: NotRequired[str]
    VersionStages: NotRequired[Sequence[str]]
    RotationToken: NotRequired[str]

class UpdateSecretRequestTypeDef(TypedDict):
    SecretId: str
    ClientRequestToken: NotRequired[str]
    Description: NotRequired[str]
    KmsKeyId: NotRequired[str]
    SecretBinary: NotRequired[BlobTypeDef]
    SecretString: NotRequired[str]

class ReplicateSecretToRegionsRequestTypeDef(TypedDict):
    SecretId: str
    AddReplicaRegions: Sequence[ReplicaRegionTypeTypeDef]
    ForceOverwriteReplicaSecret: NotRequired[bool]

class CreateSecretRequestTypeDef(TypedDict):
    Name: str
    ClientRequestToken: NotRequired[str]
    Description: NotRequired[str]
    KmsKeyId: NotRequired[str]
    SecretBinary: NotRequired[BlobTypeDef]
    SecretString: NotRequired[str]
    Tags: NotRequired[Sequence[TagTypeDef]]
    AddReplicaRegions: NotRequired[Sequence[ReplicaRegionTypeTypeDef]]
    ForceOverwriteReplicaSecret: NotRequired[bool]

class TagResourceRequestTypeDef(TypedDict):
    SecretId: str
    Tags: Sequence[TagTypeDef]

class CreateSecretResponseTypeDef(TypedDict):
    ARN: str
    Name: str
    VersionId: str
    ReplicationStatus: List[ReplicationStatusTypeTypeDef]
    ResponseMetadata: ResponseMetadataTypeDef

class RemoveRegionsFromReplicationResponseTypeDef(TypedDict):
    ARN: str
    ReplicationStatus: List[ReplicationStatusTypeTypeDef]
    ResponseMetadata: ResponseMetadataTypeDef

class ReplicateSecretToRegionsResponseTypeDef(TypedDict):
    ARN: str
    ReplicationStatus: List[ReplicationStatusTypeTypeDef]
    ResponseMetadata: ResponseMetadataTypeDef

class DescribeSecretResponseTypeDef(TypedDict):
    ARN: str
    Name: str
    Description: str
    KmsKeyId: str
    RotationEnabled: bool
    RotationLambdaARN: str
    RotationRules: RotationRulesTypeTypeDef
    LastRotatedDate: datetime
    LastChangedDate: datetime
    LastAccessedDate: datetime
    DeletedDate: datetime
    NextRotationDate: datetime
    Tags: List[TagTypeDef]
    VersionIdsToStages: Dict[str, List[str]]
    OwningService: str
    CreatedDate: datetime
    PrimaryRegion: str
    ReplicationStatus: List[ReplicationStatusTypeTypeDef]
    ResponseMetadata: ResponseMetadataTypeDef

class RotateSecretRequestTypeDef(TypedDict):
    SecretId: str
    ClientRequestToken: NotRequired[str]
    RotationLambdaARN: NotRequired[str]
    RotationRules: NotRequired[RotationRulesTypeTypeDef]
    RotateImmediately: NotRequired[bool]

class SecretListEntryTypeDef(TypedDict):
    ARN: NotRequired[str]
    Name: NotRequired[str]
    Description: NotRequired[str]
    KmsKeyId: NotRequired[str]
    RotationEnabled: NotRequired[bool]
    RotationLambdaARN: NotRequired[str]
    RotationRules: NotRequired[RotationRulesTypeTypeDef]
    LastRotatedDate: NotRequired[datetime]
    LastChangedDate: NotRequired[datetime]
    LastAccessedDate: NotRequired[datetime]
    DeletedDate: NotRequired[datetime]
    NextRotationDate: NotRequired[datetime]
    Tags: NotRequired[List[TagTypeDef]]
    SecretVersionsToStages: NotRequired[Dict[str, List[str]]]
    OwningService: NotRequired[str]
    CreatedDate: NotRequired[datetime]
    PrimaryRegion: NotRequired[str]

class ListSecretVersionIdsResponseTypeDef(TypedDict):
    Versions: List[SecretVersionsListEntryTypeDef]
    ARN: str
    Name: str
    ResponseMetadata: ResponseMetadataTypeDef
    NextToken: NotRequired[str]

class ListSecretsRequestPaginateTypeDef(TypedDict):
    IncludePlannedDeletion: NotRequired[bool]
    Filters: NotRequired[Sequence[FilterTypeDef]]
    SortOrder: NotRequired[SortOrderTypeType]
    PaginationConfig: NotRequired[PaginatorConfigTypeDef]

class ValidateResourcePolicyResponseTypeDef(TypedDict):
    PolicyValidationPassed: bool
    ValidationErrors: List[ValidationErrorsEntryTypeDef]
    ResponseMetadata: ResponseMetadataTypeDef

class ListSecretsResponseTypeDef(TypedDict):
    SecretList: List[SecretListEntryTypeDef]
    ResponseMetadata: ResponseMetadataTypeDef
    NextToken: NotRequired[str]
