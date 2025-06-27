"""
Type annotations for s3 service type definitions.

[Documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_s3/type_defs/)

Copyright 2025 Vlad Emelianov

Usage::

    ```python
    from mypy_boto3_s3.type_defs import AbortIncompleteMultipartUploadTypeDef

    data: AbortIncompleteMultipartUploadTypeDef = ...
    ```
"""

from __future__ import annotations

import sys
from datetime import datetime
from typing import IO, Any, Union

from boto3.s3.transfer import TransferConfig
from botocore.client import BaseClient
from botocore.eventstream import EventStream
from botocore.response import StreamingBody

from .literals import (
    ArchiveStatusType,
    BucketAccelerateStatusType,
    BucketCannedACLType,
    BucketLocationConstraintType,
    BucketLogsPermissionType,
    BucketVersioningStatusType,
    ChecksumAlgorithmType,
    ChecksumTypeType,
    CompressionTypeType,
    DataRedundancyType,
    DeleteMarkerReplicationStatusType,
    EventType,
    ExistingObjectReplicationStatusType,
    ExpirationStatusType,
    FileHeaderInfoType,
    FilterRuleNameType,
    IntelligentTieringAccessTierType,
    IntelligentTieringStatusType,
    InventoryFormatType,
    InventoryFrequencyType,
    InventoryIncludedObjectVersionsType,
    InventoryOptionalFieldType,
    JSONTypeType,
    LocationTypeType,
    MetadataDirectiveType,
    MetricsStatusType,
    MFADeleteStatusType,
    MFADeleteType,
    ObjectAttributesType,
    ObjectCannedACLType,
    ObjectLockLegalHoldStatusType,
    ObjectLockModeType,
    ObjectLockRetentionModeType,
    ObjectOwnershipType,
    ObjectStorageClassType,
    PartitionDateSourceType,
    PayerType,
    PermissionType,
    ProtocolType,
    QuoteFieldsType,
    ReplicaModificationsStatusType,
    ReplicationRuleStatusType,
    ReplicationStatusType,
    ReplicationTimeStatusType,
    ServerSideEncryptionType,
    SessionModeType,
    SseKmsEncryptedObjectsStatusType,
    StorageClassType,
    TaggingDirectiveType,
    TierType,
    TransitionDefaultMinimumObjectSizeType,
    TransitionStorageClassType,
    TypeType,
)

if sys.version_info >= (3, 9):
    from builtins import dict as Dict
    from builtins import list as List
    from collections.abc import Callable, Mapping, Sequence
else:
    from typing import Callable, Dict, List, Mapping, Sequence
if sys.version_info >= (3, 12):
    from typing import Literal, NotRequired, TypedDict
else:
    from typing_extensions import Literal, NotRequired, TypedDict

__all__ = (
    "AbortIncompleteMultipartUploadTypeDef",
    "AbortMultipartUploadOutputTypeDef",
    "AbortMultipartUploadRequestMultipartUploadAbortTypeDef",
    "AbortMultipartUploadRequestTypeDef",
    "AccelerateConfigurationTypeDef",
    "AccessControlPolicyTypeDef",
    "AccessControlTranslationTypeDef",
    "AnalyticsAndOperatorOutputTypeDef",
    "AnalyticsAndOperatorTypeDef",
    "AnalyticsConfigurationOutputTypeDef",
    "AnalyticsConfigurationTypeDef",
    "AnalyticsConfigurationUnionTypeDef",
    "AnalyticsExportDestinationTypeDef",
    "AnalyticsFilterOutputTypeDef",
    "AnalyticsFilterTypeDef",
    "AnalyticsS3BucketDestinationTypeDef",
    "BlobTypeDef",
    "BucketCopyRequestTypeDef",
    "BucketDownloadFileRequestTypeDef",
    "BucketDownloadFileobjRequestTypeDef",
    "BucketInfoTypeDef",
    "BucketLifecycleConfigurationTypeDef",
    "BucketLoggingStatusTypeDef",
    "BucketTypeDef",
    "BucketUploadFileRequestTypeDef",
    "BucketUploadFileobjRequestTypeDef",
    "CORSConfigurationTypeDef",
    "CORSRuleOutputTypeDef",
    "CORSRuleTypeDef",
    "CORSRuleUnionTypeDef",
    "CSVInputTypeDef",
    "CSVOutputTypeDef",
    "ChecksumTypeDef",
    "ClientCopyRequestTypeDef",
    "ClientDownloadFileRequestTypeDef",
    "ClientDownloadFileobjRequestTypeDef",
    "ClientGeneratePresignedPostRequestTypeDef",
    "ClientUploadFileRequestTypeDef",
    "ClientUploadFileobjRequestTypeDef",
    "CloudFunctionConfigurationOutputTypeDef",
    "CloudFunctionConfigurationTypeDef",
    "CloudFunctionConfigurationUnionTypeDef",
    "CommonPrefixTypeDef",
    "CompleteMultipartUploadOutputTypeDef",
    "CompleteMultipartUploadRequestMultipartUploadCompleteTypeDef",
    "CompleteMultipartUploadRequestTypeDef",
    "CompletedMultipartUploadTypeDef",
    "CompletedPartTypeDef",
    "ConditionTypeDef",
    "CopyObjectOutputTypeDef",
    "CopyObjectRequestObjectCopyFromTypeDef",
    "CopyObjectRequestObjectSummaryCopyFromTypeDef",
    "CopyObjectRequestTypeDef",
    "CopyObjectResultTypeDef",
    "CopyPartResultTypeDef",
    "CopySourceOrStrTypeDef",
    "CopySourceTypeDef",
    "CreateBucketConfigurationTypeDef",
    "CreateBucketMetadataTableConfigurationRequestTypeDef",
    "CreateBucketOutputTypeDef",
    "CreateBucketRequestBucketCreateTypeDef",
    "CreateBucketRequestServiceResourceCreateBucketTypeDef",
    "CreateBucketRequestTypeDef",
    "CreateMultipartUploadOutputTypeDef",
    "CreateMultipartUploadRequestObjectInitiateMultipartUploadTypeDef",
    "CreateMultipartUploadRequestObjectSummaryInitiateMultipartUploadTypeDef",
    "CreateMultipartUploadRequestTypeDef",
    "CreateSessionOutputTypeDef",
    "CreateSessionRequestTypeDef",
    "DefaultRetentionTypeDef",
    "DeleteBucketAnalyticsConfigurationRequestTypeDef",
    "DeleteBucketCorsRequestBucketCorsDeleteTypeDef",
    "DeleteBucketCorsRequestTypeDef",
    "DeleteBucketEncryptionRequestTypeDef",
    "DeleteBucketIntelligentTieringConfigurationRequestTypeDef",
    "DeleteBucketInventoryConfigurationRequestTypeDef",
    "DeleteBucketLifecycleRequestBucketLifecycleConfigurationDeleteTypeDef",
    "DeleteBucketLifecycleRequestBucketLifecycleDeleteTypeDef",
    "DeleteBucketLifecycleRequestTypeDef",
    "DeleteBucketMetadataTableConfigurationRequestTypeDef",
    "DeleteBucketMetricsConfigurationRequestTypeDef",
    "DeleteBucketOwnershipControlsRequestTypeDef",
    "DeleteBucketPolicyRequestBucketPolicyDeleteTypeDef",
    "DeleteBucketPolicyRequestTypeDef",
    "DeleteBucketReplicationRequestTypeDef",
    "DeleteBucketRequestBucketDeleteTypeDef",
    "DeleteBucketRequestTypeDef",
    "DeleteBucketTaggingRequestBucketTaggingDeleteTypeDef",
    "DeleteBucketTaggingRequestTypeDef",
    "DeleteBucketWebsiteRequestBucketWebsiteDeleteTypeDef",
    "DeleteBucketWebsiteRequestTypeDef",
    "DeleteMarkerEntryTypeDef",
    "DeleteMarkerReplicationTypeDef",
    "DeleteObjectOutputTypeDef",
    "DeleteObjectRequestObjectDeleteTypeDef",
    "DeleteObjectRequestObjectSummaryDeleteTypeDef",
    "DeleteObjectRequestObjectVersionDeleteTypeDef",
    "DeleteObjectRequestTypeDef",
    "DeleteObjectTaggingOutputTypeDef",
    "DeleteObjectTaggingRequestTypeDef",
    "DeleteObjectsOutputTypeDef",
    "DeleteObjectsRequestBucketDeleteObjectsTypeDef",
    "DeleteObjectsRequestTypeDef",
    "DeletePublicAccessBlockRequestTypeDef",
    "DeleteTypeDef",
    "DeletedObjectTypeDef",
    "DestinationTypeDef",
    "EmptyResponseMetadataTypeDef",
    "EncryptionConfigurationTypeDef",
    "EncryptionTypeDef",
    "ErrorDetailsTypeDef",
    "ErrorDocumentTypeDef",
    "ErrorTypeDef",
    "ExistingObjectReplicationTypeDef",
    "FileobjTypeDef",
    "FilterRuleTypeDef",
    "GetBucketAccelerateConfigurationOutputTypeDef",
    "GetBucketAccelerateConfigurationRequestTypeDef",
    "GetBucketAclOutputTypeDef",
    "GetBucketAclRequestTypeDef",
    "GetBucketAnalyticsConfigurationOutputTypeDef",
    "GetBucketAnalyticsConfigurationRequestTypeDef",
    "GetBucketCorsOutputTypeDef",
    "GetBucketCorsRequestTypeDef",
    "GetBucketEncryptionOutputTypeDef",
    "GetBucketEncryptionRequestTypeDef",
    "GetBucketIntelligentTieringConfigurationOutputTypeDef",
    "GetBucketIntelligentTieringConfigurationRequestTypeDef",
    "GetBucketInventoryConfigurationOutputTypeDef",
    "GetBucketInventoryConfigurationRequestTypeDef",
    "GetBucketLifecycleConfigurationOutputTypeDef",
    "GetBucketLifecycleConfigurationRequestTypeDef",
    "GetBucketLifecycleOutputTypeDef",
    "GetBucketLifecycleRequestTypeDef",
    "GetBucketLocationOutputTypeDef",
    "GetBucketLocationRequestTypeDef",
    "GetBucketLoggingOutputTypeDef",
    "GetBucketLoggingRequestTypeDef",
    "GetBucketMetadataTableConfigurationOutputTypeDef",
    "GetBucketMetadataTableConfigurationRequestTypeDef",
    "GetBucketMetadataTableConfigurationResultTypeDef",
    "GetBucketMetricsConfigurationOutputTypeDef",
    "GetBucketMetricsConfigurationRequestTypeDef",
    "GetBucketNotificationConfigurationRequestRequestTypeDef",
    "GetBucketNotificationConfigurationRequestTypeDef",
    "GetBucketOwnershipControlsOutputTypeDef",
    "GetBucketOwnershipControlsRequestTypeDef",
    "GetBucketPolicyOutputTypeDef",
    "GetBucketPolicyRequestTypeDef",
    "GetBucketPolicyStatusOutputTypeDef",
    "GetBucketPolicyStatusRequestTypeDef",
    "GetBucketReplicationOutputTypeDef",
    "GetBucketReplicationRequestTypeDef",
    "GetBucketRequestPaymentOutputTypeDef",
    "GetBucketRequestPaymentRequestTypeDef",
    "GetBucketTaggingOutputTypeDef",
    "GetBucketTaggingRequestTypeDef",
    "GetBucketVersioningOutputTypeDef",
    "GetBucketVersioningRequestTypeDef",
    "GetBucketWebsiteOutputTypeDef",
    "GetBucketWebsiteRequestTypeDef",
    "GetObjectAclOutputTypeDef",
    "GetObjectAclRequestTypeDef",
    "GetObjectAttributesOutputTypeDef",
    "GetObjectAttributesPartsTypeDef",
    "GetObjectAttributesRequestTypeDef",
    "GetObjectLegalHoldOutputTypeDef",
    "GetObjectLegalHoldRequestTypeDef",
    "GetObjectLockConfigurationOutputTypeDef",
    "GetObjectLockConfigurationRequestTypeDef",
    "GetObjectOutputTypeDef",
    "GetObjectRequestObjectGetTypeDef",
    "GetObjectRequestObjectSummaryGetTypeDef",
    "GetObjectRequestObjectVersionGetTypeDef",
    "GetObjectRequestTypeDef",
    "GetObjectRetentionOutputTypeDef",
    "GetObjectRetentionRequestTypeDef",
    "GetObjectTaggingOutputTypeDef",
    "GetObjectTaggingRequestTypeDef",
    "GetObjectTorrentOutputTypeDef",
    "GetObjectTorrentRequestTypeDef",
    "GetPublicAccessBlockOutputTypeDef",
    "GetPublicAccessBlockRequestTypeDef",
    "GlacierJobParametersTypeDef",
    "GrantTypeDef",
    "GranteeTypeDef",
    "HeadBucketOutputTypeDef",
    "HeadBucketRequestTypeDef",
    "HeadBucketRequestWaitExtraTypeDef",
    "HeadBucketRequestWaitTypeDef",
    "HeadObjectOutputTypeDef",
    "HeadObjectRequestObjectVersionHeadTypeDef",
    "HeadObjectRequestTypeDef",
    "HeadObjectRequestWaitExtraTypeDef",
    "HeadObjectRequestWaitTypeDef",
    "IndexDocumentTypeDef",
    "InitiatorTypeDef",
    "InputSerializationTypeDef",
    "IntelligentTieringAndOperatorOutputTypeDef",
    "IntelligentTieringAndOperatorTypeDef",
    "IntelligentTieringConfigurationOutputTypeDef",
    "IntelligentTieringConfigurationTypeDef",
    "IntelligentTieringConfigurationUnionTypeDef",
    "IntelligentTieringFilterOutputTypeDef",
    "IntelligentTieringFilterTypeDef",
    "InventoryConfigurationOutputTypeDef",
    "InventoryConfigurationTypeDef",
    "InventoryConfigurationUnionTypeDef",
    "InventoryDestinationOutputTypeDef",
    "InventoryDestinationTypeDef",
    "InventoryEncryptionOutputTypeDef",
    "InventoryEncryptionTypeDef",
    "InventoryFilterTypeDef",
    "InventoryS3BucketDestinationOutputTypeDef",
    "InventoryS3BucketDestinationTypeDef",
    "InventoryScheduleTypeDef",
    "JSONInputTypeDef",
    "JSONOutputTypeDef",
    "LambdaFunctionConfigurationOutputTypeDef",
    "LambdaFunctionConfigurationTypeDef",
    "LambdaFunctionConfigurationUnionTypeDef",
    "LifecycleConfigurationTypeDef",
    "LifecycleExpirationOutputTypeDef",
    "LifecycleExpirationTypeDef",
    "LifecycleExpirationUnionTypeDef",
    "LifecycleRuleAndOperatorOutputTypeDef",
    "LifecycleRuleAndOperatorTypeDef",
    "LifecycleRuleAndOperatorUnionTypeDef",
    "LifecycleRuleFilterOutputTypeDef",
    "LifecycleRuleFilterTypeDef",
    "LifecycleRuleFilterUnionTypeDef",
    "LifecycleRuleOutputTypeDef",
    "LifecycleRuleTypeDef",
    "LifecycleRuleUnionTypeDef",
    "ListBucketAnalyticsConfigurationsOutputTypeDef",
    "ListBucketAnalyticsConfigurationsRequestTypeDef",
    "ListBucketIntelligentTieringConfigurationsOutputTypeDef",
    "ListBucketIntelligentTieringConfigurationsRequestTypeDef",
    "ListBucketInventoryConfigurationsOutputTypeDef",
    "ListBucketInventoryConfigurationsRequestTypeDef",
    "ListBucketMetricsConfigurationsOutputTypeDef",
    "ListBucketMetricsConfigurationsRequestTypeDef",
    "ListBucketsOutputTypeDef",
    "ListBucketsRequestPaginateTypeDef",
    "ListBucketsRequestTypeDef",
    "ListDirectoryBucketsOutputTypeDef",
    "ListDirectoryBucketsRequestPaginateTypeDef",
    "ListDirectoryBucketsRequestTypeDef",
    "ListMultipartUploadsOutputTypeDef",
    "ListMultipartUploadsRequestPaginateTypeDef",
    "ListMultipartUploadsRequestTypeDef",
    "ListObjectVersionsOutputTypeDef",
    "ListObjectVersionsRequestPaginateTypeDef",
    "ListObjectVersionsRequestTypeDef",
    "ListObjectsOutputTypeDef",
    "ListObjectsRequestPaginateTypeDef",
    "ListObjectsRequestTypeDef",
    "ListObjectsV2OutputTypeDef",
    "ListObjectsV2RequestPaginateTypeDef",
    "ListObjectsV2RequestTypeDef",
    "ListPartsOutputTypeDef",
    "ListPartsRequestPaginateTypeDef",
    "ListPartsRequestTypeDef",
    "LocationInfoTypeDef",
    "LoggingEnabledOutputTypeDef",
    "LoggingEnabledTypeDef",
    "LoggingEnabledUnionTypeDef",
    "MetadataEntryTypeDef",
    "MetadataTableConfigurationResultTypeDef",
    "MetadataTableConfigurationTypeDef",
    "MetricsAndOperatorOutputTypeDef",
    "MetricsAndOperatorTypeDef",
    "MetricsConfigurationOutputTypeDef",
    "MetricsConfigurationTypeDef",
    "MetricsConfigurationUnionTypeDef",
    "MetricsFilterOutputTypeDef",
    "MetricsFilterTypeDef",
    "MetricsTypeDef",
    "MultipartUploadTypeDef",
    "NoncurrentVersionExpirationTypeDef",
    "NoncurrentVersionTransitionTypeDef",
    "NotificationConfigurationDeprecatedResponseTypeDef",
    "NotificationConfigurationDeprecatedTypeDef",
    "NotificationConfigurationFilterOutputTypeDef",
    "NotificationConfigurationFilterTypeDef",
    "NotificationConfigurationFilterUnionTypeDef",
    "NotificationConfigurationResponseTypeDef",
    "NotificationConfigurationTypeDef",
    "ObjectCopyRequestTypeDef",
    "ObjectDownloadFileRequestTypeDef",
    "ObjectDownloadFileobjRequestTypeDef",
    "ObjectIdentifierTypeDef",
    "ObjectLockConfigurationTypeDef",
    "ObjectLockLegalHoldTypeDef",
    "ObjectLockRetentionOutputTypeDef",
    "ObjectLockRetentionTypeDef",
    "ObjectLockRetentionUnionTypeDef",
    "ObjectLockRuleTypeDef",
    "ObjectPartTypeDef",
    "ObjectTypeDef",
    "ObjectUploadFileRequestTypeDef",
    "ObjectUploadFileobjRequestTypeDef",
    "ObjectVersionTypeDef",
    "OutputLocationTypeDef",
    "OutputSerializationTypeDef",
    "OwnerTypeDef",
    "OwnershipControlsOutputTypeDef",
    "OwnershipControlsRuleTypeDef",
    "OwnershipControlsTypeDef",
    "OwnershipControlsUnionTypeDef",
    "PaginatorConfigTypeDef",
    "PartTypeDef",
    "PartitionedPrefixTypeDef",
    "PolicyStatusTypeDef",
    "ProgressEventTypeDef",
    "ProgressTypeDef",
    "PublicAccessBlockConfigurationTypeDef",
    "PutBucketAccelerateConfigurationRequestTypeDef",
    "PutBucketAclRequestBucketAclPutTypeDef",
    "PutBucketAclRequestTypeDef",
    "PutBucketAnalyticsConfigurationRequestTypeDef",
    "PutBucketCorsRequestBucketCorsPutTypeDef",
    "PutBucketCorsRequestTypeDef",
    "PutBucketEncryptionRequestTypeDef",
    "PutBucketIntelligentTieringConfigurationRequestTypeDef",
    "PutBucketInventoryConfigurationRequestTypeDef",
    "PutBucketLifecycleConfigurationOutputTypeDef",
    "PutBucketLifecycleConfigurationRequestBucketLifecycleConfigurationPutTypeDef",
    "PutBucketLifecycleConfigurationRequestTypeDef",
    "PutBucketLifecycleRequestBucketLifecyclePutTypeDef",
    "PutBucketLifecycleRequestTypeDef",
    "PutBucketLoggingRequestBucketLoggingPutTypeDef",
    "PutBucketLoggingRequestTypeDef",
    "PutBucketMetricsConfigurationRequestTypeDef",
    "PutBucketNotificationConfigurationRequestBucketNotificationPutTypeDef",
    "PutBucketNotificationConfigurationRequestTypeDef",
    "PutBucketNotificationRequestTypeDef",
    "PutBucketOwnershipControlsRequestTypeDef",
    "PutBucketPolicyRequestBucketPolicyPutTypeDef",
    "PutBucketPolicyRequestTypeDef",
    "PutBucketReplicationRequestTypeDef",
    "PutBucketRequestPaymentRequestBucketRequestPaymentPutTypeDef",
    "PutBucketRequestPaymentRequestTypeDef",
    "PutBucketTaggingRequestBucketTaggingPutTypeDef",
    "PutBucketTaggingRequestTypeDef",
    "PutBucketVersioningRequestBucketVersioningEnableTypeDef",
    "PutBucketVersioningRequestBucketVersioningPutTypeDef",
    "PutBucketVersioningRequestBucketVersioningSuspendTypeDef",
    "PutBucketVersioningRequestTypeDef",
    "PutBucketWebsiteRequestBucketWebsitePutTypeDef",
    "PutBucketWebsiteRequestTypeDef",
    "PutObjectAclOutputTypeDef",
    "PutObjectAclRequestObjectAclPutTypeDef",
    "PutObjectAclRequestTypeDef",
    "PutObjectLegalHoldOutputTypeDef",
    "PutObjectLegalHoldRequestTypeDef",
    "PutObjectLockConfigurationOutputTypeDef",
    "PutObjectLockConfigurationRequestTypeDef",
    "PutObjectOutputTypeDef",
    "PutObjectRequestBucketPutObjectTypeDef",
    "PutObjectRequestObjectPutTypeDef",
    "PutObjectRequestObjectSummaryPutTypeDef",
    "PutObjectRequestTypeDef",
    "PutObjectRetentionOutputTypeDef",
    "PutObjectRetentionRequestTypeDef",
    "PutObjectTaggingOutputTypeDef",
    "PutObjectTaggingRequestTypeDef",
    "PutPublicAccessBlockRequestTypeDef",
    "QueueConfigurationDeprecatedOutputTypeDef",
    "QueueConfigurationDeprecatedTypeDef",
    "QueueConfigurationDeprecatedUnionTypeDef",
    "QueueConfigurationOutputTypeDef",
    "QueueConfigurationTypeDef",
    "QueueConfigurationUnionTypeDef",
    "RecordsEventTypeDef",
    "RedirectAllRequestsToTypeDef",
    "RedirectTypeDef",
    "RenameObjectRequestTypeDef",
    "ReplicaModificationsTypeDef",
    "ReplicationConfigurationOutputTypeDef",
    "ReplicationConfigurationTypeDef",
    "ReplicationConfigurationUnionTypeDef",
    "ReplicationRuleAndOperatorOutputTypeDef",
    "ReplicationRuleAndOperatorTypeDef",
    "ReplicationRuleFilterOutputTypeDef",
    "ReplicationRuleFilterTypeDef",
    "ReplicationRuleOutputTypeDef",
    "ReplicationRuleTypeDef",
    "ReplicationTimeTypeDef",
    "ReplicationTimeValueTypeDef",
    "RequestPaymentConfigurationTypeDef",
    "RequestProgressTypeDef",
    "ResponseMetadataTypeDef",
    "RestoreObjectOutputTypeDef",
    "RestoreObjectRequestObjectRestoreObjectTypeDef",
    "RestoreObjectRequestObjectSummaryRestoreObjectTypeDef",
    "RestoreObjectRequestTypeDef",
    "RestoreRequestTypeDef",
    "RestoreStatusTypeDef",
    "RoutingRuleTypeDef",
    "RuleOutputTypeDef",
    "RuleTypeDef",
    "RuleUnionTypeDef",
    "S3KeyFilterOutputTypeDef",
    "S3KeyFilterTypeDef",
    "S3KeyFilterUnionTypeDef",
    "S3LocationTypeDef",
    "S3TablesDestinationResultTypeDef",
    "S3TablesDestinationTypeDef",
    "SSEKMSTypeDef",
    "ScanRangeTypeDef",
    "SelectObjectContentEventStreamTypeDef",
    "SelectObjectContentOutputTypeDef",
    "SelectObjectContentRequestTypeDef",
    "SelectParametersTypeDef",
    "ServerSideEncryptionByDefaultTypeDef",
    "ServerSideEncryptionConfigurationOutputTypeDef",
    "ServerSideEncryptionConfigurationTypeDef",
    "ServerSideEncryptionConfigurationUnionTypeDef",
    "ServerSideEncryptionRuleTypeDef",
    "SessionCredentialsTypeDef",
    "SourceSelectionCriteriaTypeDef",
    "SseKmsEncryptedObjectsTypeDef",
    "StatsEventTypeDef",
    "StatsTypeDef",
    "StorageClassAnalysisDataExportTypeDef",
    "StorageClassAnalysisTypeDef",
    "TagTypeDef",
    "TaggingTypeDef",
    "TargetGrantTypeDef",
    "TargetObjectKeyFormatOutputTypeDef",
    "TargetObjectKeyFormatTypeDef",
    "TargetObjectKeyFormatUnionTypeDef",
    "TieringTypeDef",
    "TimestampTypeDef",
    "TopicConfigurationDeprecatedOutputTypeDef",
    "TopicConfigurationDeprecatedTypeDef",
    "TopicConfigurationDeprecatedUnionTypeDef",
    "TopicConfigurationOutputTypeDef",
    "TopicConfigurationTypeDef",
    "TopicConfigurationUnionTypeDef",
    "TransitionOutputTypeDef",
    "TransitionTypeDef",
    "TransitionUnionTypeDef",
    "UploadPartCopyOutputTypeDef",
    "UploadPartCopyRequestMultipartUploadPartCopyFromTypeDef",
    "UploadPartCopyRequestTypeDef",
    "UploadPartOutputTypeDef",
    "UploadPartRequestMultipartUploadPartUploadTypeDef",
    "UploadPartRequestTypeDef",
    "VersioningConfigurationTypeDef",
    "WaiterConfigTypeDef",
    "WebsiteConfigurationTypeDef",
    "WriteGetObjectResponseRequestTypeDef",
)

class AbortIncompleteMultipartUploadTypeDef(TypedDict):
    DaysAfterInitiation: NotRequired[int]

class ResponseMetadataTypeDef(TypedDict):
    RequestId: str
    HTTPStatusCode: int
    HTTPHeaders: Dict[str, str]
    RetryAttempts: int
    HostId: NotRequired[str]

TimestampTypeDef = Union[datetime, str]

class AccelerateConfigurationTypeDef(TypedDict):
    Status: NotRequired[BucketAccelerateStatusType]

class OwnerTypeDef(TypedDict):
    DisplayName: NotRequired[str]
    ID: NotRequired[str]

class AccessControlTranslationTypeDef(TypedDict):
    Owner: Literal["Destination"]

class TagTypeDef(TypedDict):
    Key: str
    Value: str

class AnalyticsS3BucketDestinationTypeDef(TypedDict):
    Format: Literal["CSV"]
    Bucket: str
    BucketAccountId: NotRequired[str]
    Prefix: NotRequired[str]

BlobTypeDef = Union[str, bytes, IO[Any], StreamingBody]

class CopySourceTypeDef(TypedDict):
    Bucket: str
    Key: str
    VersionId: NotRequired[str]

class BucketDownloadFileRequestTypeDef(TypedDict):
    Key: str
    Filename: str
    ExtraArgs: NotRequired[Dict[str, Any] | None]
    Callback: NotRequired[Callable[..., Any] | None]
    Config: NotRequired[TransferConfig | None]

FileobjTypeDef = Union[IO[Any], StreamingBody]
BucketInfoTypeDef = TypedDict(
    "BucketInfoTypeDef",
    {
        "DataRedundancy": NotRequired[DataRedundancyType],
        "Type": NotRequired[Literal["Directory"]],
    },
)

class BucketTypeDef(TypedDict):
    Name: NotRequired[str]
    CreationDate: NotRequired[datetime]
    BucketRegion: NotRequired[str]

class BucketUploadFileRequestTypeDef(TypedDict):
    Filename: str
    Key: str
    ExtraArgs: NotRequired[Dict[str, Any] | None]
    Callback: NotRequired[Callable[..., Any] | None]
    Config: NotRequired[TransferConfig | None]

class CORSRuleOutputTypeDef(TypedDict):
    AllowedMethods: List[str]
    AllowedOrigins: List[str]
    ID: NotRequired[str]
    AllowedHeaders: NotRequired[List[str]]
    ExposeHeaders: NotRequired[List[str]]
    MaxAgeSeconds: NotRequired[int]

class CORSRuleTypeDef(TypedDict):
    AllowedMethods: Sequence[str]
    AllowedOrigins: Sequence[str]
    ID: NotRequired[str]
    AllowedHeaders: NotRequired[Sequence[str]]
    ExposeHeaders: NotRequired[Sequence[str]]
    MaxAgeSeconds: NotRequired[int]

class CSVInputTypeDef(TypedDict):
    FileHeaderInfo: NotRequired[FileHeaderInfoType]
    Comments: NotRequired[str]
    QuoteEscapeCharacter: NotRequired[str]
    RecordDelimiter: NotRequired[str]
    FieldDelimiter: NotRequired[str]
    QuoteCharacter: NotRequired[str]
    AllowQuotedRecordDelimiter: NotRequired[bool]

class CSVOutputTypeDef(TypedDict):
    QuoteFields: NotRequired[QuoteFieldsType]
    QuoteEscapeCharacter: NotRequired[str]
    RecordDelimiter: NotRequired[str]
    FieldDelimiter: NotRequired[str]
    QuoteCharacter: NotRequired[str]

class ChecksumTypeDef(TypedDict):
    ChecksumCRC32: NotRequired[str]
    ChecksumCRC32C: NotRequired[str]
    ChecksumCRC64NVME: NotRequired[str]
    ChecksumSHA1: NotRequired[str]
    ChecksumSHA256: NotRequired[str]
    ChecksumType: NotRequired[ChecksumTypeType]

class ClientDownloadFileRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    Filename: str
    ExtraArgs: NotRequired[Dict[str, Any] | None]
    Callback: NotRequired[Callable[..., Any] | None]
    Config: NotRequired[TransferConfig | None]

class ClientGeneratePresignedPostRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    Fields: NotRequired[Dict[str, Any] | None]
    Conditions: NotRequired[List[Any] | Dict[str, Any] | None]
    ExpiresIn: NotRequired[int]

class ClientUploadFileRequestTypeDef(TypedDict):
    Filename: str
    Bucket: str
    Key: str
    ExtraArgs: NotRequired[Dict[str, Any] | None]
    Callback: NotRequired[Callable[..., Any] | None]
    Config: NotRequired[TransferConfig | None]

class CloudFunctionConfigurationOutputTypeDef(TypedDict):
    Id: NotRequired[str]
    Event: NotRequired[EventType]
    Events: NotRequired[List[EventType]]
    CloudFunction: NotRequired[str]
    InvocationRole: NotRequired[str]

class CloudFunctionConfigurationTypeDef(TypedDict):
    Id: NotRequired[str]
    Event: NotRequired[EventType]
    Events: NotRequired[Sequence[EventType]]
    CloudFunction: NotRequired[str]
    InvocationRole: NotRequired[str]

class CommonPrefixTypeDef(TypedDict):
    Prefix: NotRequired[str]

class CompletedPartTypeDef(TypedDict):
    ETag: NotRequired[str]
    ChecksumCRC32: NotRequired[str]
    ChecksumCRC32C: NotRequired[str]
    ChecksumCRC64NVME: NotRequired[str]
    ChecksumSHA1: NotRequired[str]
    ChecksumSHA256: NotRequired[str]
    PartNumber: NotRequired[int]

class ConditionTypeDef(TypedDict):
    HttpErrorCodeReturnedEquals: NotRequired[str]
    KeyPrefixEquals: NotRequired[str]

class CopyObjectResultTypeDef(TypedDict):
    ETag: NotRequired[str]
    LastModified: NotRequired[datetime]
    ChecksumType: NotRequired[ChecksumTypeType]
    ChecksumCRC32: NotRequired[str]
    ChecksumCRC32C: NotRequired[str]
    ChecksumCRC64NVME: NotRequired[str]
    ChecksumSHA1: NotRequired[str]
    ChecksumSHA256: NotRequired[str]

class CopyPartResultTypeDef(TypedDict):
    ETag: NotRequired[str]
    LastModified: NotRequired[datetime]
    ChecksumCRC32: NotRequired[str]
    ChecksumCRC32C: NotRequired[str]
    ChecksumCRC64NVME: NotRequired[str]
    ChecksumSHA1: NotRequired[str]
    ChecksumSHA256: NotRequired[str]

LocationInfoTypeDef = TypedDict(
    "LocationInfoTypeDef",
    {
        "Type": NotRequired[LocationTypeType],
        "Name": NotRequired[str],
    },
)

class SessionCredentialsTypeDef(TypedDict):
    AccessKeyId: str
    SecretAccessKey: str
    SessionToken: str
    Expiration: datetime

class CreateSessionRequestTypeDef(TypedDict):
    Bucket: str
    SessionMode: NotRequired[SessionModeType]
    ServerSideEncryption: NotRequired[ServerSideEncryptionType]
    SSEKMSKeyId: NotRequired[str]
    SSEKMSEncryptionContext: NotRequired[str]
    BucketKeyEnabled: NotRequired[bool]

class DefaultRetentionTypeDef(TypedDict):
    Mode: NotRequired[ObjectLockRetentionModeType]
    Days: NotRequired[int]
    Years: NotRequired[int]

class DeleteBucketAnalyticsConfigurationRequestTypeDef(TypedDict):
    Bucket: str
    Id: str
    ExpectedBucketOwner: NotRequired[str]

class DeleteBucketCorsRequestBucketCorsDeleteTypeDef(TypedDict):
    ExpectedBucketOwner: NotRequired[str]

class DeleteBucketCorsRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class DeleteBucketEncryptionRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class DeleteBucketIntelligentTieringConfigurationRequestTypeDef(TypedDict):
    Bucket: str
    Id: str
    ExpectedBucketOwner: NotRequired[str]

class DeleteBucketInventoryConfigurationRequestTypeDef(TypedDict):
    Bucket: str
    Id: str
    ExpectedBucketOwner: NotRequired[str]

class DeleteBucketLifecycleRequestBucketLifecycleConfigurationDeleteTypeDef(TypedDict):
    ExpectedBucketOwner: NotRequired[str]

class DeleteBucketLifecycleRequestBucketLifecycleDeleteTypeDef(TypedDict):
    ExpectedBucketOwner: NotRequired[str]

class DeleteBucketLifecycleRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class DeleteBucketMetadataTableConfigurationRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class DeleteBucketMetricsConfigurationRequestTypeDef(TypedDict):
    Bucket: str
    Id: str
    ExpectedBucketOwner: NotRequired[str]

class DeleteBucketOwnershipControlsRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class DeleteBucketPolicyRequestBucketPolicyDeleteTypeDef(TypedDict):
    ExpectedBucketOwner: NotRequired[str]

class DeleteBucketPolicyRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class DeleteBucketReplicationRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class DeleteBucketRequestBucketDeleteTypeDef(TypedDict):
    ExpectedBucketOwner: NotRequired[str]

class DeleteBucketRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class DeleteBucketTaggingRequestBucketTaggingDeleteTypeDef(TypedDict):
    ExpectedBucketOwner: NotRequired[str]

class DeleteBucketTaggingRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class DeleteBucketWebsiteRequestBucketWebsiteDeleteTypeDef(TypedDict):
    ExpectedBucketOwner: NotRequired[str]

class DeleteBucketWebsiteRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class DeleteMarkerReplicationTypeDef(TypedDict):
    Status: NotRequired[DeleteMarkerReplicationStatusType]

class DeleteObjectTaggingRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    VersionId: NotRequired[str]
    ExpectedBucketOwner: NotRequired[str]

class DeletedObjectTypeDef(TypedDict):
    Key: NotRequired[str]
    VersionId: NotRequired[str]
    DeleteMarker: NotRequired[bool]
    DeleteMarkerVersionId: NotRequired[str]

class ErrorTypeDef(TypedDict):
    Key: NotRequired[str]
    VersionId: NotRequired[str]
    Code: NotRequired[str]
    Message: NotRequired[str]

class DeletePublicAccessBlockRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class EncryptionConfigurationTypeDef(TypedDict):
    ReplicaKmsKeyID: NotRequired[str]

class EncryptionTypeDef(TypedDict):
    EncryptionType: ServerSideEncryptionType
    KMSKeyId: NotRequired[str]
    KMSContext: NotRequired[str]

class ErrorDetailsTypeDef(TypedDict):
    ErrorCode: NotRequired[str]
    ErrorMessage: NotRequired[str]

class ErrorDocumentTypeDef(TypedDict):
    Key: str

class ExistingObjectReplicationTypeDef(TypedDict):
    Status: ExistingObjectReplicationStatusType

class FilterRuleTypeDef(TypedDict):
    Name: NotRequired[FilterRuleNameType]
    Value: NotRequired[str]

class GetBucketAccelerateConfigurationRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]
    RequestPayer: NotRequired[Literal["requester"]]

class GetBucketAclRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class GetBucketAnalyticsConfigurationRequestTypeDef(TypedDict):
    Bucket: str
    Id: str
    ExpectedBucketOwner: NotRequired[str]

class GetBucketCorsRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class GetBucketEncryptionRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class GetBucketIntelligentTieringConfigurationRequestTypeDef(TypedDict):
    Bucket: str
    Id: str
    ExpectedBucketOwner: NotRequired[str]

class GetBucketInventoryConfigurationRequestTypeDef(TypedDict):
    Bucket: str
    Id: str
    ExpectedBucketOwner: NotRequired[str]

class GetBucketLifecycleConfigurationRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class GetBucketLifecycleRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class GetBucketLocationRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class GetBucketLoggingRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class GetBucketMetadataTableConfigurationRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class GetBucketMetricsConfigurationRequestTypeDef(TypedDict):
    Bucket: str
    Id: str
    ExpectedBucketOwner: NotRequired[str]

class GetBucketNotificationConfigurationRequestRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class GetBucketNotificationConfigurationRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class GetBucketOwnershipControlsRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class GetBucketPolicyRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class PolicyStatusTypeDef(TypedDict):
    IsPublic: NotRequired[bool]

class GetBucketPolicyStatusRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class GetBucketReplicationRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class GetBucketRequestPaymentRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class GetBucketTaggingRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class GetBucketVersioningRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class IndexDocumentTypeDef(TypedDict):
    Suffix: str

RedirectAllRequestsToTypeDef = TypedDict(
    "RedirectAllRequestsToTypeDef",
    {
        "HostName": str,
        "Protocol": NotRequired[ProtocolType],
    },
)

class GetBucketWebsiteRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class GetObjectAclRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    VersionId: NotRequired[str]
    RequestPayer: NotRequired[Literal["requester"]]
    ExpectedBucketOwner: NotRequired[str]

class ObjectPartTypeDef(TypedDict):
    PartNumber: NotRequired[int]
    Size: NotRequired[int]
    ChecksumCRC32: NotRequired[str]
    ChecksumCRC32C: NotRequired[str]
    ChecksumCRC64NVME: NotRequired[str]
    ChecksumSHA1: NotRequired[str]
    ChecksumSHA256: NotRequired[str]

class GetObjectAttributesRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    ObjectAttributes: Sequence[ObjectAttributesType]
    VersionId: NotRequired[str]
    MaxParts: NotRequired[int]
    PartNumberMarker: NotRequired[int]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]
    RequestPayer: NotRequired[Literal["requester"]]
    ExpectedBucketOwner: NotRequired[str]

class ObjectLockLegalHoldTypeDef(TypedDict):
    Status: NotRequired[ObjectLockLegalHoldStatusType]

class GetObjectLegalHoldRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    VersionId: NotRequired[str]
    RequestPayer: NotRequired[Literal["requester"]]
    ExpectedBucketOwner: NotRequired[str]

class GetObjectLockConfigurationRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class ObjectLockRetentionOutputTypeDef(TypedDict):
    Mode: NotRequired[ObjectLockRetentionModeType]
    RetainUntilDate: NotRequired[datetime]

class GetObjectRetentionRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    VersionId: NotRequired[str]
    RequestPayer: NotRequired[Literal["requester"]]
    ExpectedBucketOwner: NotRequired[str]

class GetObjectTaggingRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    VersionId: NotRequired[str]
    ExpectedBucketOwner: NotRequired[str]
    RequestPayer: NotRequired[Literal["requester"]]

class GetObjectTorrentRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    RequestPayer: NotRequired[Literal["requester"]]
    ExpectedBucketOwner: NotRequired[str]

class PublicAccessBlockConfigurationTypeDef(TypedDict):
    BlockPublicAcls: NotRequired[bool]
    IgnorePublicAcls: NotRequired[bool]
    BlockPublicPolicy: NotRequired[bool]
    RestrictPublicBuckets: NotRequired[bool]

class GetPublicAccessBlockRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class GlacierJobParametersTypeDef(TypedDict):
    Tier: TierType

GranteeTypeDef = TypedDict(
    "GranteeTypeDef",
    {
        "Type": TypeType,
        "DisplayName": NotRequired[str],
        "EmailAddress": NotRequired[str],
        "ID": NotRequired[str],
        "URI": NotRequired[str],
    },
)

class HeadBucketRequestTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]

class WaiterConfigTypeDef(TypedDict):
    Delay: NotRequired[int]
    MaxAttempts: NotRequired[int]

class InitiatorTypeDef(TypedDict):
    ID: NotRequired[str]
    DisplayName: NotRequired[str]

JSONInputTypeDef = TypedDict(
    "JSONInputTypeDef",
    {
        "Type": NotRequired[JSONTypeType],
    },
)

class TieringTypeDef(TypedDict):
    Days: int
    AccessTier: IntelligentTieringAccessTierType

class InventoryFilterTypeDef(TypedDict):
    Prefix: str

class InventoryScheduleTypeDef(TypedDict):
    Frequency: InventoryFrequencyType

class SSEKMSTypeDef(TypedDict):
    KeyId: str

class JSONOutputTypeDef(TypedDict):
    RecordDelimiter: NotRequired[str]

class LifecycleExpirationOutputTypeDef(TypedDict):
    Date: NotRequired[datetime]
    Days: NotRequired[int]
    ExpiredObjectDeleteMarker: NotRequired[bool]

class NoncurrentVersionExpirationTypeDef(TypedDict):
    NoncurrentDays: NotRequired[int]
    NewerNoncurrentVersions: NotRequired[int]

class NoncurrentVersionTransitionTypeDef(TypedDict):
    NoncurrentDays: NotRequired[int]
    StorageClass: NotRequired[TransitionStorageClassType]
    NewerNoncurrentVersions: NotRequired[int]

class TransitionOutputTypeDef(TypedDict):
    Date: NotRequired[datetime]
    Days: NotRequired[int]
    StorageClass: NotRequired[TransitionStorageClassType]

class ListBucketAnalyticsConfigurationsRequestTypeDef(TypedDict):
    Bucket: str
    ContinuationToken: NotRequired[str]
    ExpectedBucketOwner: NotRequired[str]

class ListBucketIntelligentTieringConfigurationsRequestTypeDef(TypedDict):
    Bucket: str
    ContinuationToken: NotRequired[str]
    ExpectedBucketOwner: NotRequired[str]

class ListBucketInventoryConfigurationsRequestTypeDef(TypedDict):
    Bucket: str
    ContinuationToken: NotRequired[str]
    ExpectedBucketOwner: NotRequired[str]

class ListBucketMetricsConfigurationsRequestTypeDef(TypedDict):
    Bucket: str
    ContinuationToken: NotRequired[str]
    ExpectedBucketOwner: NotRequired[str]

class PaginatorConfigTypeDef(TypedDict):
    MaxItems: NotRequired[int]
    PageSize: NotRequired[int]
    StartingToken: NotRequired[str]

class ListBucketsRequestTypeDef(TypedDict):
    MaxBuckets: NotRequired[int]
    ContinuationToken: NotRequired[str]
    Prefix: NotRequired[str]
    BucketRegion: NotRequired[str]

class ListDirectoryBucketsRequestTypeDef(TypedDict):
    ContinuationToken: NotRequired[str]
    MaxDirectoryBuckets: NotRequired[int]

class ListMultipartUploadsRequestTypeDef(TypedDict):
    Bucket: str
    Delimiter: NotRequired[str]
    EncodingType: NotRequired[Literal["url"]]
    KeyMarker: NotRequired[str]
    MaxUploads: NotRequired[int]
    Prefix: NotRequired[str]
    UploadIdMarker: NotRequired[str]
    ExpectedBucketOwner: NotRequired[str]
    RequestPayer: NotRequired[Literal["requester"]]

class ListObjectVersionsRequestTypeDef(TypedDict):
    Bucket: str
    Delimiter: NotRequired[str]
    EncodingType: NotRequired[Literal["url"]]
    KeyMarker: NotRequired[str]
    MaxKeys: NotRequired[int]
    Prefix: NotRequired[str]
    VersionIdMarker: NotRequired[str]
    ExpectedBucketOwner: NotRequired[str]
    RequestPayer: NotRequired[Literal["requester"]]
    OptionalObjectAttributes: NotRequired[Sequence[Literal["RestoreStatus"]]]

class ListObjectsRequestTypeDef(TypedDict):
    Bucket: str
    Delimiter: NotRequired[str]
    EncodingType: NotRequired[Literal["url"]]
    Marker: NotRequired[str]
    MaxKeys: NotRequired[int]
    Prefix: NotRequired[str]
    RequestPayer: NotRequired[Literal["requester"]]
    ExpectedBucketOwner: NotRequired[str]
    OptionalObjectAttributes: NotRequired[Sequence[Literal["RestoreStatus"]]]

class ListObjectsV2RequestTypeDef(TypedDict):
    Bucket: str
    Delimiter: NotRequired[str]
    EncodingType: NotRequired[Literal["url"]]
    MaxKeys: NotRequired[int]
    Prefix: NotRequired[str]
    ContinuationToken: NotRequired[str]
    FetchOwner: NotRequired[bool]
    StartAfter: NotRequired[str]
    RequestPayer: NotRequired[Literal["requester"]]
    ExpectedBucketOwner: NotRequired[str]
    OptionalObjectAttributes: NotRequired[Sequence[Literal["RestoreStatus"]]]

class PartTypeDef(TypedDict):
    PartNumber: NotRequired[int]
    LastModified: NotRequired[datetime]
    ETag: NotRequired[str]
    Size: NotRequired[int]
    ChecksumCRC32: NotRequired[str]
    ChecksumCRC32C: NotRequired[str]
    ChecksumCRC64NVME: NotRequired[str]
    ChecksumSHA1: NotRequired[str]
    ChecksumSHA256: NotRequired[str]

class ListPartsRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    UploadId: str
    MaxParts: NotRequired[int]
    PartNumberMarker: NotRequired[int]
    RequestPayer: NotRequired[Literal["requester"]]
    ExpectedBucketOwner: NotRequired[str]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]

class MetadataEntryTypeDef(TypedDict):
    Name: NotRequired[str]
    Value: NotRequired[str]

class S3TablesDestinationResultTypeDef(TypedDict):
    TableBucketArn: str
    TableName: str
    TableArn: str
    TableNamespace: str

class S3TablesDestinationTypeDef(TypedDict):
    TableBucketArn: str
    TableName: str

class ReplicationTimeValueTypeDef(TypedDict):
    Minutes: NotRequired[int]

class QueueConfigurationDeprecatedOutputTypeDef(TypedDict):
    Id: NotRequired[str]
    Event: NotRequired[EventType]
    Events: NotRequired[List[EventType]]
    Queue: NotRequired[str]

class TopicConfigurationDeprecatedOutputTypeDef(TypedDict):
    Id: NotRequired[str]
    Events: NotRequired[List[EventType]]
    Event: NotRequired[EventType]
    Topic: NotRequired[str]

class ObjectDownloadFileRequestTypeDef(TypedDict):
    Filename: str
    ExtraArgs: NotRequired[Dict[str, Any] | None]
    Callback: NotRequired[Callable[..., Any] | None]
    Config: NotRequired[TransferConfig | None]

class RestoreStatusTypeDef(TypedDict):
    IsRestoreInProgress: NotRequired[bool]
    RestoreExpiryDate: NotRequired[datetime]

class ObjectUploadFileRequestTypeDef(TypedDict):
    Filename: str
    ExtraArgs: NotRequired[Dict[str, Any] | None]
    Callback: NotRequired[Callable[..., Any] | None]
    Config: NotRequired[TransferConfig | None]

class OwnershipControlsRuleTypeDef(TypedDict):
    ObjectOwnership: ObjectOwnershipType

class PartitionedPrefixTypeDef(TypedDict):
    PartitionDateSource: NotRequired[PartitionDateSourceType]

class ProgressTypeDef(TypedDict):
    BytesScanned: NotRequired[int]
    BytesProcessed: NotRequired[int]
    BytesReturned: NotRequired[int]

class PutBucketPolicyRequestBucketPolicyPutTypeDef(TypedDict):
    Policy: str
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ConfirmRemoveSelfBucketAccess: NotRequired[bool]
    ExpectedBucketOwner: NotRequired[str]

class PutBucketPolicyRequestTypeDef(TypedDict):
    Bucket: str
    Policy: str
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ConfirmRemoveSelfBucketAccess: NotRequired[bool]
    ExpectedBucketOwner: NotRequired[str]

class RequestPaymentConfigurationTypeDef(TypedDict):
    Payer: PayerType

class PutBucketVersioningRequestBucketVersioningEnableTypeDef(TypedDict):
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    MFA: NotRequired[str]
    ExpectedBucketOwner: NotRequired[str]

class VersioningConfigurationTypeDef(TypedDict):
    MFADelete: NotRequired[MFADeleteType]
    Status: NotRequired[BucketVersioningStatusType]

class PutBucketVersioningRequestBucketVersioningSuspendTypeDef(TypedDict):
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    MFA: NotRequired[str]
    ExpectedBucketOwner: NotRequired[str]

class QueueConfigurationDeprecatedTypeDef(TypedDict):
    Id: NotRequired[str]
    Event: NotRequired[EventType]
    Events: NotRequired[Sequence[EventType]]
    Queue: NotRequired[str]

class RecordsEventTypeDef(TypedDict):
    Payload: NotRequired[bytes]

RedirectTypeDef = TypedDict(
    "RedirectTypeDef",
    {
        "HostName": NotRequired[str],
        "HttpRedirectCode": NotRequired[str],
        "Protocol": NotRequired[ProtocolType],
        "ReplaceKeyPrefixWith": NotRequired[str],
        "ReplaceKeyWith": NotRequired[str],
    },
)

class ReplicaModificationsTypeDef(TypedDict):
    Status: ReplicaModificationsStatusType

class RequestProgressTypeDef(TypedDict):
    Enabled: NotRequired[bool]

class ScanRangeTypeDef(TypedDict):
    Start: NotRequired[int]
    End: NotRequired[int]

class ServerSideEncryptionByDefaultTypeDef(TypedDict):
    SSEAlgorithm: ServerSideEncryptionType
    KMSMasterKeyID: NotRequired[str]

class SseKmsEncryptedObjectsTypeDef(TypedDict):
    Status: SseKmsEncryptedObjectsStatusType

class StatsTypeDef(TypedDict):
    BytesScanned: NotRequired[int]
    BytesProcessed: NotRequired[int]
    BytesReturned: NotRequired[int]

class TopicConfigurationDeprecatedTypeDef(TypedDict):
    Id: NotRequired[str]
    Events: NotRequired[Sequence[EventType]]
    Event: NotRequired[EventType]
    Topic: NotRequired[str]

class AbortMultipartUploadOutputTypeDef(TypedDict):
    RequestCharged: Literal["requester"]
    ResponseMetadata: ResponseMetadataTypeDef

class CompleteMultipartUploadOutputTypeDef(TypedDict):
    Location: str
    Bucket: str
    Key: str
    Expiration: str
    ETag: str
    ChecksumCRC32: str
    ChecksumCRC32C: str
    ChecksumCRC64NVME: str
    ChecksumSHA1: str
    ChecksumSHA256: str
    ChecksumType: ChecksumTypeType
    ServerSideEncryption: ServerSideEncryptionType
    VersionId: str
    SSEKMSKeyId: str
    BucketKeyEnabled: bool
    RequestCharged: Literal["requester"]
    ResponseMetadata: ResponseMetadataTypeDef

class CreateBucketOutputTypeDef(TypedDict):
    Location: str
    ResponseMetadata: ResponseMetadataTypeDef

class CreateMultipartUploadOutputTypeDef(TypedDict):
    AbortDate: datetime
    AbortRuleId: str
    Bucket: str
    Key: str
    UploadId: str
    ServerSideEncryption: ServerSideEncryptionType
    SSECustomerAlgorithm: str
    SSECustomerKeyMD5: str
    SSEKMSKeyId: str
    SSEKMSEncryptionContext: str
    BucketKeyEnabled: bool
    RequestCharged: Literal["requester"]
    ChecksumAlgorithm: ChecksumAlgorithmType
    ChecksumType: ChecksumTypeType
    ResponseMetadata: ResponseMetadataTypeDef

class DeleteObjectOutputTypeDef(TypedDict):
    DeleteMarker: bool
    VersionId: str
    RequestCharged: Literal["requester"]
    ResponseMetadata: ResponseMetadataTypeDef

class DeleteObjectTaggingOutputTypeDef(TypedDict):
    VersionId: str
    ResponseMetadata: ResponseMetadataTypeDef

class EmptyResponseMetadataTypeDef(TypedDict):
    ResponseMetadata: ResponseMetadataTypeDef

class GetBucketAccelerateConfigurationOutputTypeDef(TypedDict):
    Status: BucketAccelerateStatusType
    RequestCharged: Literal["requester"]
    ResponseMetadata: ResponseMetadataTypeDef

class GetBucketLocationOutputTypeDef(TypedDict):
    LocationConstraint: BucketLocationConstraintType
    ResponseMetadata: ResponseMetadataTypeDef

class GetBucketPolicyOutputTypeDef(TypedDict):
    Policy: str
    ResponseMetadata: ResponseMetadataTypeDef

class GetBucketRequestPaymentOutputTypeDef(TypedDict):
    Payer: PayerType
    ResponseMetadata: ResponseMetadataTypeDef

class GetBucketVersioningOutputTypeDef(TypedDict):
    Status: BucketVersioningStatusType
    MFADelete: MFADeleteStatusType
    ResponseMetadata: ResponseMetadataTypeDef

class GetObjectOutputTypeDef(TypedDict):
    Body: StreamingBody
    DeleteMarker: bool
    AcceptRanges: str
    Expiration: str
    Restore: str
    LastModified: datetime
    ContentLength: int
    ETag: str
    ChecksumCRC32: str
    ChecksumCRC32C: str
    ChecksumCRC64NVME: str
    ChecksumSHA1: str
    ChecksumSHA256: str
    ChecksumType: ChecksumTypeType
    MissingMeta: int
    VersionId: str
    CacheControl: str
    ContentDisposition: str
    ContentEncoding: str
    ContentLanguage: str
    ContentRange: str
    ContentType: str
    Expires: datetime
    WebsiteRedirectLocation: str
    ServerSideEncryption: ServerSideEncryptionType
    Metadata: Dict[str, str]
    SSECustomerAlgorithm: str
    SSECustomerKeyMD5: str
    SSEKMSKeyId: str
    BucketKeyEnabled: bool
    StorageClass: StorageClassType
    RequestCharged: Literal["requester"]
    ReplicationStatus: ReplicationStatusType
    PartsCount: int
    TagCount: int
    ObjectLockMode: ObjectLockModeType
    ObjectLockRetainUntilDate: datetime
    ObjectLockLegalHoldStatus: ObjectLockLegalHoldStatusType
    ResponseMetadata: ResponseMetadataTypeDef

class GetObjectTorrentOutputTypeDef(TypedDict):
    Body: StreamingBody
    RequestCharged: Literal["requester"]
    ResponseMetadata: ResponseMetadataTypeDef

class HeadBucketOutputTypeDef(TypedDict):
    BucketLocationType: LocationTypeType
    BucketLocationName: str
    BucketRegion: str
    AccessPointAlias: bool
    ResponseMetadata: ResponseMetadataTypeDef

class HeadObjectOutputTypeDef(TypedDict):
    DeleteMarker: bool
    AcceptRanges: str
    Expiration: str
    Restore: str
    ArchiveStatus: ArchiveStatusType
    LastModified: datetime
    ContentLength: int
    ChecksumCRC32: str
    ChecksumCRC32C: str
    ChecksumCRC64NVME: str
    ChecksumSHA1: str
    ChecksumSHA256: str
    ChecksumType: ChecksumTypeType
    ETag: str
    MissingMeta: int
    VersionId: str
    CacheControl: str
    ContentDisposition: str
    ContentEncoding: str
    ContentLanguage: str
    ContentType: str
    ContentRange: str
    Expires: datetime
    WebsiteRedirectLocation: str
    ServerSideEncryption: ServerSideEncryptionType
    Metadata: Dict[str, str]
    SSECustomerAlgorithm: str
    SSECustomerKeyMD5: str
    SSEKMSKeyId: str
    BucketKeyEnabled: bool
    StorageClass: StorageClassType
    RequestCharged: Literal["requester"]
    ReplicationStatus: ReplicationStatusType
    PartsCount: int
    TagCount: int
    ObjectLockMode: ObjectLockModeType
    ObjectLockRetainUntilDate: datetime
    ObjectLockLegalHoldStatus: ObjectLockLegalHoldStatusType
    ResponseMetadata: ResponseMetadataTypeDef

class PutBucketLifecycleConfigurationOutputTypeDef(TypedDict):
    TransitionDefaultMinimumObjectSize: TransitionDefaultMinimumObjectSizeType
    ResponseMetadata: ResponseMetadataTypeDef

class PutObjectAclOutputTypeDef(TypedDict):
    RequestCharged: Literal["requester"]
    ResponseMetadata: ResponseMetadataTypeDef

class PutObjectLegalHoldOutputTypeDef(TypedDict):
    RequestCharged: Literal["requester"]
    ResponseMetadata: ResponseMetadataTypeDef

class PutObjectLockConfigurationOutputTypeDef(TypedDict):
    RequestCharged: Literal["requester"]
    ResponseMetadata: ResponseMetadataTypeDef

class PutObjectOutputTypeDef(TypedDict):
    Expiration: str
    ETag: str
    ChecksumCRC32: str
    ChecksumCRC32C: str
    ChecksumCRC64NVME: str
    ChecksumSHA1: str
    ChecksumSHA256: str
    ChecksumType: ChecksumTypeType
    ServerSideEncryption: ServerSideEncryptionType
    VersionId: str
    SSECustomerAlgorithm: str
    SSECustomerKeyMD5: str
    SSEKMSKeyId: str
    SSEKMSEncryptionContext: str
    BucketKeyEnabled: bool
    Size: int
    RequestCharged: Literal["requester"]
    ResponseMetadata: ResponseMetadataTypeDef

class PutObjectRetentionOutputTypeDef(TypedDict):
    RequestCharged: Literal["requester"]
    ResponseMetadata: ResponseMetadataTypeDef

class PutObjectTaggingOutputTypeDef(TypedDict):
    VersionId: str
    ResponseMetadata: ResponseMetadataTypeDef

class RestoreObjectOutputTypeDef(TypedDict):
    RequestCharged: Literal["requester"]
    RestoreOutputPath: str
    ResponseMetadata: ResponseMetadataTypeDef

class UploadPartOutputTypeDef(TypedDict):
    ServerSideEncryption: ServerSideEncryptionType
    ETag: str
    ChecksumCRC32: str
    ChecksumCRC32C: str
    ChecksumCRC64NVME: str
    ChecksumSHA1: str
    ChecksumSHA256: str
    SSECustomerAlgorithm: str
    SSECustomerKeyMD5: str
    SSEKMSKeyId: str
    BucketKeyEnabled: bool
    RequestCharged: Literal["requester"]
    ResponseMetadata: ResponseMetadataTypeDef

class AbortMultipartUploadRequestMultipartUploadAbortTypeDef(TypedDict):
    RequestPayer: NotRequired[Literal["requester"]]
    ExpectedBucketOwner: NotRequired[str]
    IfMatchInitiatedTime: NotRequired[TimestampTypeDef]

class AbortMultipartUploadRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    UploadId: str
    RequestPayer: NotRequired[Literal["requester"]]
    ExpectedBucketOwner: NotRequired[str]
    IfMatchInitiatedTime: NotRequired[TimestampTypeDef]

class CreateMultipartUploadRequestObjectInitiateMultipartUploadTypeDef(TypedDict):
    ACL: NotRequired[ObjectCannedACLType]
    CacheControl: NotRequired[str]
    ContentDisposition: NotRequired[str]
    ContentEncoding: NotRequired[str]
    ContentLanguage: NotRequired[str]
    ContentType: NotRequired[str]
    Expires: NotRequired[TimestampTypeDef]
    GrantFullControl: NotRequired[str]
    GrantRead: NotRequired[str]
    GrantReadACP: NotRequired[str]
    GrantWriteACP: NotRequired[str]
    Metadata: NotRequired[Mapping[str, str]]
    ServerSideEncryption: NotRequired[ServerSideEncryptionType]
    StorageClass: NotRequired[StorageClassType]
    WebsiteRedirectLocation: NotRequired[str]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]
    SSEKMSKeyId: NotRequired[str]
    SSEKMSEncryptionContext: NotRequired[str]
    BucketKeyEnabled: NotRequired[bool]
    RequestPayer: NotRequired[Literal["requester"]]
    Tagging: NotRequired[str]
    ObjectLockMode: NotRequired[ObjectLockModeType]
    ObjectLockRetainUntilDate: NotRequired[TimestampTypeDef]
    ObjectLockLegalHoldStatus: NotRequired[ObjectLockLegalHoldStatusType]
    ExpectedBucketOwner: NotRequired[str]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ChecksumType: NotRequired[ChecksumTypeType]

class CreateMultipartUploadRequestObjectSummaryInitiateMultipartUploadTypeDef(TypedDict):
    ACL: NotRequired[ObjectCannedACLType]
    CacheControl: NotRequired[str]
    ContentDisposition: NotRequired[str]
    ContentEncoding: NotRequired[str]
    ContentLanguage: NotRequired[str]
    ContentType: NotRequired[str]
    Expires: NotRequired[TimestampTypeDef]
    GrantFullControl: NotRequired[str]
    GrantRead: NotRequired[str]
    GrantReadACP: NotRequired[str]
    GrantWriteACP: NotRequired[str]
    Metadata: NotRequired[Mapping[str, str]]
    ServerSideEncryption: NotRequired[ServerSideEncryptionType]
    StorageClass: NotRequired[StorageClassType]
    WebsiteRedirectLocation: NotRequired[str]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]
    SSEKMSKeyId: NotRequired[str]
    SSEKMSEncryptionContext: NotRequired[str]
    BucketKeyEnabled: NotRequired[bool]
    RequestPayer: NotRequired[Literal["requester"]]
    Tagging: NotRequired[str]
    ObjectLockMode: NotRequired[ObjectLockModeType]
    ObjectLockRetainUntilDate: NotRequired[TimestampTypeDef]
    ObjectLockLegalHoldStatus: NotRequired[ObjectLockLegalHoldStatusType]
    ExpectedBucketOwner: NotRequired[str]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ChecksumType: NotRequired[ChecksumTypeType]

class CreateMultipartUploadRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    ACL: NotRequired[ObjectCannedACLType]
    CacheControl: NotRequired[str]
    ContentDisposition: NotRequired[str]
    ContentEncoding: NotRequired[str]
    ContentLanguage: NotRequired[str]
    ContentType: NotRequired[str]
    Expires: NotRequired[TimestampTypeDef]
    GrantFullControl: NotRequired[str]
    GrantRead: NotRequired[str]
    GrantReadACP: NotRequired[str]
    GrantWriteACP: NotRequired[str]
    Metadata: NotRequired[Mapping[str, str]]
    ServerSideEncryption: NotRequired[ServerSideEncryptionType]
    StorageClass: NotRequired[StorageClassType]
    WebsiteRedirectLocation: NotRequired[str]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]
    SSEKMSKeyId: NotRequired[str]
    SSEKMSEncryptionContext: NotRequired[str]
    BucketKeyEnabled: NotRequired[bool]
    RequestPayer: NotRequired[Literal["requester"]]
    Tagging: NotRequired[str]
    ObjectLockMode: NotRequired[ObjectLockModeType]
    ObjectLockRetainUntilDate: NotRequired[TimestampTypeDef]
    ObjectLockLegalHoldStatus: NotRequired[ObjectLockLegalHoldStatusType]
    ExpectedBucketOwner: NotRequired[str]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ChecksumType: NotRequired[ChecksumTypeType]

class DeleteObjectRequestObjectDeleteTypeDef(TypedDict):
    MFA: NotRequired[str]
    VersionId: NotRequired[str]
    RequestPayer: NotRequired[Literal["requester"]]
    BypassGovernanceRetention: NotRequired[bool]
    ExpectedBucketOwner: NotRequired[str]
    IfMatch: NotRequired[str]
    IfMatchLastModifiedTime: NotRequired[TimestampTypeDef]
    IfMatchSize: NotRequired[int]

class DeleteObjectRequestObjectSummaryDeleteTypeDef(TypedDict):
    MFA: NotRequired[str]
    VersionId: NotRequired[str]
    RequestPayer: NotRequired[Literal["requester"]]
    BypassGovernanceRetention: NotRequired[bool]
    ExpectedBucketOwner: NotRequired[str]
    IfMatch: NotRequired[str]
    IfMatchLastModifiedTime: NotRequired[TimestampTypeDef]
    IfMatchSize: NotRequired[int]

class DeleteObjectRequestObjectVersionDeleteTypeDef(TypedDict):
    MFA: NotRequired[str]
    RequestPayer: NotRequired[Literal["requester"]]
    BypassGovernanceRetention: NotRequired[bool]
    ExpectedBucketOwner: NotRequired[str]
    IfMatch: NotRequired[str]
    IfMatchLastModifiedTime: NotRequired[TimestampTypeDef]
    IfMatchSize: NotRequired[int]

class DeleteObjectRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    MFA: NotRequired[str]
    VersionId: NotRequired[str]
    RequestPayer: NotRequired[Literal["requester"]]
    BypassGovernanceRetention: NotRequired[bool]
    ExpectedBucketOwner: NotRequired[str]
    IfMatch: NotRequired[str]
    IfMatchLastModifiedTime: NotRequired[TimestampTypeDef]
    IfMatchSize: NotRequired[int]

class GetObjectRequestObjectGetTypeDef(TypedDict):
    IfMatch: NotRequired[str]
    IfModifiedSince: NotRequired[TimestampTypeDef]
    IfNoneMatch: NotRequired[str]
    IfUnmodifiedSince: NotRequired[TimestampTypeDef]
    Range: NotRequired[str]
    ResponseCacheControl: NotRequired[str]
    ResponseContentDisposition: NotRequired[str]
    ResponseContentEncoding: NotRequired[str]
    ResponseContentLanguage: NotRequired[str]
    ResponseContentType: NotRequired[str]
    ResponseExpires: NotRequired[TimestampTypeDef]
    VersionId: NotRequired[str]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]
    RequestPayer: NotRequired[Literal["requester"]]
    PartNumber: NotRequired[int]
    ExpectedBucketOwner: NotRequired[str]
    ChecksumMode: NotRequired[Literal["ENABLED"]]

class GetObjectRequestObjectSummaryGetTypeDef(TypedDict):
    IfMatch: NotRequired[str]
    IfModifiedSince: NotRequired[TimestampTypeDef]
    IfNoneMatch: NotRequired[str]
    IfUnmodifiedSince: NotRequired[TimestampTypeDef]
    Range: NotRequired[str]
    ResponseCacheControl: NotRequired[str]
    ResponseContentDisposition: NotRequired[str]
    ResponseContentEncoding: NotRequired[str]
    ResponseContentLanguage: NotRequired[str]
    ResponseContentType: NotRequired[str]
    ResponseExpires: NotRequired[TimestampTypeDef]
    VersionId: NotRequired[str]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]
    RequestPayer: NotRequired[Literal["requester"]]
    PartNumber: NotRequired[int]
    ExpectedBucketOwner: NotRequired[str]
    ChecksumMode: NotRequired[Literal["ENABLED"]]

class GetObjectRequestObjectVersionGetTypeDef(TypedDict):
    IfMatch: NotRequired[str]
    IfModifiedSince: NotRequired[TimestampTypeDef]
    IfNoneMatch: NotRequired[str]
    IfUnmodifiedSince: NotRequired[TimestampTypeDef]
    Range: NotRequired[str]
    ResponseCacheControl: NotRequired[str]
    ResponseContentDisposition: NotRequired[str]
    ResponseContentEncoding: NotRequired[str]
    ResponseContentLanguage: NotRequired[str]
    ResponseContentType: NotRequired[str]
    ResponseExpires: NotRequired[TimestampTypeDef]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]
    RequestPayer: NotRequired[Literal["requester"]]
    PartNumber: NotRequired[int]
    ExpectedBucketOwner: NotRequired[str]
    ChecksumMode: NotRequired[Literal["ENABLED"]]

class GetObjectRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    IfMatch: NotRequired[str]
    IfModifiedSince: NotRequired[TimestampTypeDef]
    IfNoneMatch: NotRequired[str]
    IfUnmodifiedSince: NotRequired[TimestampTypeDef]
    Range: NotRequired[str]
    ResponseCacheControl: NotRequired[str]
    ResponseContentDisposition: NotRequired[str]
    ResponseContentEncoding: NotRequired[str]
    ResponseContentLanguage: NotRequired[str]
    ResponseContentType: NotRequired[str]
    ResponseExpires: NotRequired[TimestampTypeDef]
    VersionId: NotRequired[str]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]
    RequestPayer: NotRequired[Literal["requester"]]
    PartNumber: NotRequired[int]
    ExpectedBucketOwner: NotRequired[str]
    ChecksumMode: NotRequired[Literal["ENABLED"]]

class HeadObjectRequestObjectVersionHeadTypeDef(TypedDict):
    IfMatch: NotRequired[str]
    IfModifiedSince: NotRequired[TimestampTypeDef]
    IfNoneMatch: NotRequired[str]
    IfUnmodifiedSince: NotRequired[TimestampTypeDef]
    Range: NotRequired[str]
    ResponseCacheControl: NotRequired[str]
    ResponseContentDisposition: NotRequired[str]
    ResponseContentEncoding: NotRequired[str]
    ResponseContentLanguage: NotRequired[str]
    ResponseContentType: NotRequired[str]
    ResponseExpires: NotRequired[TimestampTypeDef]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]
    RequestPayer: NotRequired[Literal["requester"]]
    PartNumber: NotRequired[int]
    ExpectedBucketOwner: NotRequired[str]
    ChecksumMode: NotRequired[Literal["ENABLED"]]

class HeadObjectRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    IfMatch: NotRequired[str]
    IfModifiedSince: NotRequired[TimestampTypeDef]
    IfNoneMatch: NotRequired[str]
    IfUnmodifiedSince: NotRequired[TimestampTypeDef]
    Range: NotRequired[str]
    ResponseCacheControl: NotRequired[str]
    ResponseContentDisposition: NotRequired[str]
    ResponseContentEncoding: NotRequired[str]
    ResponseContentLanguage: NotRequired[str]
    ResponseContentType: NotRequired[str]
    ResponseExpires: NotRequired[TimestampTypeDef]
    VersionId: NotRequired[str]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]
    RequestPayer: NotRequired[Literal["requester"]]
    PartNumber: NotRequired[int]
    ExpectedBucketOwner: NotRequired[str]
    ChecksumMode: NotRequired[Literal["ENABLED"]]

class LifecycleExpirationTypeDef(TypedDict):
    Date: NotRequired[TimestampTypeDef]
    Days: NotRequired[int]
    ExpiredObjectDeleteMarker: NotRequired[bool]

class ObjectIdentifierTypeDef(TypedDict):
    Key: str
    VersionId: NotRequired[str]
    ETag: NotRequired[str]
    LastModifiedTime: NotRequired[TimestampTypeDef]
    Size: NotRequired[int]

class ObjectLockRetentionTypeDef(TypedDict):
    Mode: NotRequired[ObjectLockRetentionModeType]
    RetainUntilDate: NotRequired[TimestampTypeDef]

class RenameObjectRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    RenameSource: str
    DestinationIfMatch: NotRequired[str]
    DestinationIfNoneMatch: NotRequired[str]
    DestinationIfModifiedSince: NotRequired[TimestampTypeDef]
    DestinationIfUnmodifiedSince: NotRequired[TimestampTypeDef]
    SourceIfMatch: NotRequired[str]
    SourceIfNoneMatch: NotRequired[str]
    SourceIfModifiedSince: NotRequired[TimestampTypeDef]
    SourceIfUnmodifiedSince: NotRequired[TimestampTypeDef]
    ClientToken: NotRequired[str]

class TransitionTypeDef(TypedDict):
    Date: NotRequired[TimestampTypeDef]
    Days: NotRequired[int]
    StorageClass: NotRequired[TransitionStorageClassType]

class PutBucketAccelerateConfigurationRequestTypeDef(TypedDict):
    Bucket: str
    AccelerateConfiguration: AccelerateConfigurationTypeDef
    ExpectedBucketOwner: NotRequired[str]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]

class DeleteMarkerEntryTypeDef(TypedDict):
    Owner: NotRequired[OwnerTypeDef]
    Key: NotRequired[str]
    VersionId: NotRequired[str]
    IsLatest: NotRequired[bool]
    LastModified: NotRequired[datetime]

class AnalyticsAndOperatorOutputTypeDef(TypedDict):
    Prefix: NotRequired[str]
    Tags: NotRequired[List[TagTypeDef]]

class AnalyticsAndOperatorTypeDef(TypedDict):
    Prefix: NotRequired[str]
    Tags: NotRequired[Sequence[TagTypeDef]]

class GetBucketTaggingOutputTypeDef(TypedDict):
    TagSet: List[TagTypeDef]
    ResponseMetadata: ResponseMetadataTypeDef

class GetObjectTaggingOutputTypeDef(TypedDict):
    VersionId: str
    TagSet: List[TagTypeDef]
    ResponseMetadata: ResponseMetadataTypeDef

class IntelligentTieringAndOperatorOutputTypeDef(TypedDict):
    Prefix: NotRequired[str]
    Tags: NotRequired[List[TagTypeDef]]

class IntelligentTieringAndOperatorTypeDef(TypedDict):
    Prefix: NotRequired[str]
    Tags: NotRequired[Sequence[TagTypeDef]]

class LifecycleRuleAndOperatorOutputTypeDef(TypedDict):
    Prefix: NotRequired[str]
    Tags: NotRequired[List[TagTypeDef]]
    ObjectSizeGreaterThan: NotRequired[int]
    ObjectSizeLessThan: NotRequired[int]

class LifecycleRuleAndOperatorTypeDef(TypedDict):
    Prefix: NotRequired[str]
    Tags: NotRequired[Sequence[TagTypeDef]]
    ObjectSizeGreaterThan: NotRequired[int]
    ObjectSizeLessThan: NotRequired[int]

class MetricsAndOperatorOutputTypeDef(TypedDict):
    Prefix: NotRequired[str]
    Tags: NotRequired[List[TagTypeDef]]
    AccessPointArn: NotRequired[str]

class MetricsAndOperatorTypeDef(TypedDict):
    Prefix: NotRequired[str]
    Tags: NotRequired[Sequence[TagTypeDef]]
    AccessPointArn: NotRequired[str]

class ReplicationRuleAndOperatorOutputTypeDef(TypedDict):
    Prefix: NotRequired[str]
    Tags: NotRequired[List[TagTypeDef]]

class ReplicationRuleAndOperatorTypeDef(TypedDict):
    Prefix: NotRequired[str]
    Tags: NotRequired[Sequence[TagTypeDef]]

class TaggingTypeDef(TypedDict):
    TagSet: Sequence[TagTypeDef]

class AnalyticsExportDestinationTypeDef(TypedDict):
    S3BucketDestination: AnalyticsS3BucketDestinationTypeDef

class PutObjectRequestBucketPutObjectTypeDef(TypedDict):
    Key: str
    ACL: NotRequired[ObjectCannedACLType]
    Body: NotRequired[BlobTypeDef]
    CacheControl: NotRequired[str]
    ContentDisposition: NotRequired[str]
    ContentEncoding: NotRequired[str]
    ContentLanguage: NotRequired[str]
    ContentLength: NotRequired[int]
    ContentMD5: NotRequired[str]
    ContentType: NotRequired[str]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ChecksumCRC32: NotRequired[str]
    ChecksumCRC32C: NotRequired[str]
    ChecksumCRC64NVME: NotRequired[str]
    ChecksumSHA1: NotRequired[str]
    ChecksumSHA256: NotRequired[str]
    Expires: NotRequired[TimestampTypeDef]
    IfMatch: NotRequired[str]
    IfNoneMatch: NotRequired[str]
    GrantFullControl: NotRequired[str]
    GrantRead: NotRequired[str]
    GrantReadACP: NotRequired[str]
    GrantWriteACP: NotRequired[str]
    WriteOffsetBytes: NotRequired[int]
    Metadata: NotRequired[Mapping[str, str]]
    ServerSideEncryption: NotRequired[ServerSideEncryptionType]
    StorageClass: NotRequired[StorageClassType]
    WebsiteRedirectLocation: NotRequired[str]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]
    SSEKMSKeyId: NotRequired[str]
    SSEKMSEncryptionContext: NotRequired[str]
    BucketKeyEnabled: NotRequired[bool]
    RequestPayer: NotRequired[Literal["requester"]]
    Tagging: NotRequired[str]
    ObjectLockMode: NotRequired[ObjectLockModeType]
    ObjectLockRetainUntilDate: NotRequired[TimestampTypeDef]
    ObjectLockLegalHoldStatus: NotRequired[ObjectLockLegalHoldStatusType]
    ExpectedBucketOwner: NotRequired[str]

class PutObjectRequestObjectPutTypeDef(TypedDict):
    ACL: NotRequired[ObjectCannedACLType]
    Body: NotRequired[BlobTypeDef]
    CacheControl: NotRequired[str]
    ContentDisposition: NotRequired[str]
    ContentEncoding: NotRequired[str]
    ContentLanguage: NotRequired[str]
    ContentLength: NotRequired[int]
    ContentMD5: NotRequired[str]
    ContentType: NotRequired[str]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ChecksumCRC32: NotRequired[str]
    ChecksumCRC32C: NotRequired[str]
    ChecksumCRC64NVME: NotRequired[str]
    ChecksumSHA1: NotRequired[str]
    ChecksumSHA256: NotRequired[str]
    Expires: NotRequired[TimestampTypeDef]
    IfMatch: NotRequired[str]
    IfNoneMatch: NotRequired[str]
    GrantFullControl: NotRequired[str]
    GrantRead: NotRequired[str]
    GrantReadACP: NotRequired[str]
    GrantWriteACP: NotRequired[str]
    WriteOffsetBytes: NotRequired[int]
    Metadata: NotRequired[Mapping[str, str]]
    ServerSideEncryption: NotRequired[ServerSideEncryptionType]
    StorageClass: NotRequired[StorageClassType]
    WebsiteRedirectLocation: NotRequired[str]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]
    SSEKMSKeyId: NotRequired[str]
    SSEKMSEncryptionContext: NotRequired[str]
    BucketKeyEnabled: NotRequired[bool]
    RequestPayer: NotRequired[Literal["requester"]]
    Tagging: NotRequired[str]
    ObjectLockMode: NotRequired[ObjectLockModeType]
    ObjectLockRetainUntilDate: NotRequired[TimestampTypeDef]
    ObjectLockLegalHoldStatus: NotRequired[ObjectLockLegalHoldStatusType]
    ExpectedBucketOwner: NotRequired[str]

class PutObjectRequestObjectSummaryPutTypeDef(TypedDict):
    ACL: NotRequired[ObjectCannedACLType]
    Body: NotRequired[BlobTypeDef]
    CacheControl: NotRequired[str]
    ContentDisposition: NotRequired[str]
    ContentEncoding: NotRequired[str]
    ContentLanguage: NotRequired[str]
    ContentLength: NotRequired[int]
    ContentMD5: NotRequired[str]
    ContentType: NotRequired[str]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ChecksumCRC32: NotRequired[str]
    ChecksumCRC32C: NotRequired[str]
    ChecksumCRC64NVME: NotRequired[str]
    ChecksumSHA1: NotRequired[str]
    ChecksumSHA256: NotRequired[str]
    Expires: NotRequired[TimestampTypeDef]
    IfMatch: NotRequired[str]
    IfNoneMatch: NotRequired[str]
    GrantFullControl: NotRequired[str]
    GrantRead: NotRequired[str]
    GrantReadACP: NotRequired[str]
    GrantWriteACP: NotRequired[str]
    WriteOffsetBytes: NotRequired[int]
    Metadata: NotRequired[Mapping[str, str]]
    ServerSideEncryption: NotRequired[ServerSideEncryptionType]
    StorageClass: NotRequired[StorageClassType]
    WebsiteRedirectLocation: NotRequired[str]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]
    SSEKMSKeyId: NotRequired[str]
    SSEKMSEncryptionContext: NotRequired[str]
    BucketKeyEnabled: NotRequired[bool]
    RequestPayer: NotRequired[Literal["requester"]]
    Tagging: NotRequired[str]
    ObjectLockMode: NotRequired[ObjectLockModeType]
    ObjectLockRetainUntilDate: NotRequired[TimestampTypeDef]
    ObjectLockLegalHoldStatus: NotRequired[ObjectLockLegalHoldStatusType]
    ExpectedBucketOwner: NotRequired[str]

class PutObjectRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    ACL: NotRequired[ObjectCannedACLType]
    Body: NotRequired[BlobTypeDef]
    CacheControl: NotRequired[str]
    ContentDisposition: NotRequired[str]
    ContentEncoding: NotRequired[str]
    ContentLanguage: NotRequired[str]
    ContentLength: NotRequired[int]
    ContentMD5: NotRequired[str]
    ContentType: NotRequired[str]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ChecksumCRC32: NotRequired[str]
    ChecksumCRC32C: NotRequired[str]
    ChecksumCRC64NVME: NotRequired[str]
    ChecksumSHA1: NotRequired[str]
    ChecksumSHA256: NotRequired[str]
    Expires: NotRequired[TimestampTypeDef]
    IfMatch: NotRequired[str]
    IfNoneMatch: NotRequired[str]
    GrantFullControl: NotRequired[str]
    GrantRead: NotRequired[str]
    GrantReadACP: NotRequired[str]
    GrantWriteACP: NotRequired[str]
    WriteOffsetBytes: NotRequired[int]
    Metadata: NotRequired[Mapping[str, str]]
    ServerSideEncryption: NotRequired[ServerSideEncryptionType]
    StorageClass: NotRequired[StorageClassType]
    WebsiteRedirectLocation: NotRequired[str]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]
    SSEKMSKeyId: NotRequired[str]
    SSEKMSEncryptionContext: NotRequired[str]
    BucketKeyEnabled: NotRequired[bool]
    RequestPayer: NotRequired[Literal["requester"]]
    Tagging: NotRequired[str]
    ObjectLockMode: NotRequired[ObjectLockModeType]
    ObjectLockRetainUntilDate: NotRequired[TimestampTypeDef]
    ObjectLockLegalHoldStatus: NotRequired[ObjectLockLegalHoldStatusType]
    ExpectedBucketOwner: NotRequired[str]

class UploadPartRequestMultipartUploadPartUploadTypeDef(TypedDict):
    Body: NotRequired[BlobTypeDef]
    ContentLength: NotRequired[int]
    ContentMD5: NotRequired[str]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ChecksumCRC32: NotRequired[str]
    ChecksumCRC32C: NotRequired[str]
    ChecksumCRC64NVME: NotRequired[str]
    ChecksumSHA1: NotRequired[str]
    ChecksumSHA256: NotRequired[str]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]
    RequestPayer: NotRequired[Literal["requester"]]
    ExpectedBucketOwner: NotRequired[str]

class UploadPartRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    PartNumber: int
    UploadId: str
    Body: NotRequired[BlobTypeDef]
    ContentLength: NotRequired[int]
    ContentMD5: NotRequired[str]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ChecksumCRC32: NotRequired[str]
    ChecksumCRC32C: NotRequired[str]
    ChecksumCRC64NVME: NotRequired[str]
    ChecksumSHA1: NotRequired[str]
    ChecksumSHA256: NotRequired[str]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]
    RequestPayer: NotRequired[Literal["requester"]]
    ExpectedBucketOwner: NotRequired[str]

class WriteGetObjectResponseRequestTypeDef(TypedDict):
    RequestRoute: str
    RequestToken: str
    Body: NotRequired[BlobTypeDef]
    StatusCode: NotRequired[int]
    ErrorCode: NotRequired[str]
    ErrorMessage: NotRequired[str]
    AcceptRanges: NotRequired[str]
    CacheControl: NotRequired[str]
    ContentDisposition: NotRequired[str]
    ContentEncoding: NotRequired[str]
    ContentLanguage: NotRequired[str]
    ContentLength: NotRequired[int]
    ContentRange: NotRequired[str]
    ContentType: NotRequired[str]
    ChecksumCRC32: NotRequired[str]
    ChecksumCRC32C: NotRequired[str]
    ChecksumCRC64NVME: NotRequired[str]
    ChecksumSHA1: NotRequired[str]
    ChecksumSHA256: NotRequired[str]
    DeleteMarker: NotRequired[bool]
    ETag: NotRequired[str]
    Expires: NotRequired[TimestampTypeDef]
    Expiration: NotRequired[str]
    LastModified: NotRequired[TimestampTypeDef]
    MissingMeta: NotRequired[int]
    Metadata: NotRequired[Mapping[str, str]]
    ObjectLockMode: NotRequired[ObjectLockModeType]
    ObjectLockLegalHoldStatus: NotRequired[ObjectLockLegalHoldStatusType]
    ObjectLockRetainUntilDate: NotRequired[TimestampTypeDef]
    PartsCount: NotRequired[int]
    ReplicationStatus: NotRequired[ReplicationStatusType]
    RequestCharged: NotRequired[Literal["requester"]]
    Restore: NotRequired[str]
    ServerSideEncryption: NotRequired[ServerSideEncryptionType]
    SSECustomerAlgorithm: NotRequired[str]
    SSEKMSKeyId: NotRequired[str]
    StorageClass: NotRequired[StorageClassType]
    TagCount: NotRequired[int]
    VersionId: NotRequired[str]
    BucketKeyEnabled: NotRequired[bool]

class BucketCopyRequestTypeDef(TypedDict):
    CopySource: CopySourceTypeDef
    Key: str
    ExtraArgs: NotRequired[Dict[str, Any] | None]
    Callback: NotRequired[Callable[..., Any] | None]
    SourceClient: NotRequired[BaseClient | None]
    Config: NotRequired[TransferConfig | None]

class ClientCopyRequestTypeDef(TypedDict):
    CopySource: CopySourceTypeDef
    Bucket: str
    Key: str
    ExtraArgs: NotRequired[Dict[str, Any] | None]
    Callback: NotRequired[Callable[..., Any] | None]
    SourceClient: NotRequired[BaseClient | None]
    Config: NotRequired[TransferConfig | None]

CopySourceOrStrTypeDef = Union[str, CopySourceTypeDef]

class ObjectCopyRequestTypeDef(TypedDict):
    CopySource: CopySourceTypeDef
    ExtraArgs: NotRequired[Dict[str, Any] | None]
    Callback: NotRequired[Callable[..., Any] | None]
    SourceClient: NotRequired[BaseClient | None]
    Config: NotRequired[TransferConfig | None]

class BucketDownloadFileobjRequestTypeDef(TypedDict):
    Key: str
    Fileobj: FileobjTypeDef
    ExtraArgs: NotRequired[Dict[str, Any] | None]
    Callback: NotRequired[Callable[..., Any] | None]
    Config: NotRequired[TransferConfig | None]

class BucketUploadFileobjRequestTypeDef(TypedDict):
    Fileobj: FileobjTypeDef
    Key: str
    ExtraArgs: NotRequired[Dict[str, Any] | None]
    Callback: NotRequired[Callable[..., Any] | None]
    Config: NotRequired[TransferConfig | None]

class ClientDownloadFileobjRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    Fileobj: FileobjTypeDef
    ExtraArgs: NotRequired[Dict[str, Any] | None]
    Callback: NotRequired[Callable[..., Any] | None]
    Config: NotRequired[TransferConfig | None]

class ClientUploadFileobjRequestTypeDef(TypedDict):
    Fileobj: FileobjTypeDef
    Bucket: str
    Key: str
    ExtraArgs: NotRequired[Dict[str, Any] | None]
    Callback: NotRequired[Callable[..., Any] | None]
    Config: NotRequired[TransferConfig | None]

class ObjectDownloadFileobjRequestTypeDef(TypedDict):
    Fileobj: FileobjTypeDef
    ExtraArgs: NotRequired[Dict[str, Any] | None]
    Callback: NotRequired[Callable[..., Any] | None]
    Config: NotRequired[TransferConfig | None]

class ObjectUploadFileobjRequestTypeDef(TypedDict):
    Fileobj: FileobjTypeDef
    ExtraArgs: NotRequired[Dict[str, Any] | None]
    Callback: NotRequired[Callable[..., Any] | None]
    Config: NotRequired[TransferConfig | None]

class ListBucketsOutputTypeDef(TypedDict):
    Buckets: List[BucketTypeDef]
    Owner: OwnerTypeDef
    ContinuationToken: str
    Prefix: str
    ResponseMetadata: ResponseMetadataTypeDef

class ListDirectoryBucketsOutputTypeDef(TypedDict):
    Buckets: List[BucketTypeDef]
    ContinuationToken: str
    ResponseMetadata: ResponseMetadataTypeDef

class GetBucketCorsOutputTypeDef(TypedDict):
    CORSRules: List[CORSRuleOutputTypeDef]
    ResponseMetadata: ResponseMetadataTypeDef

CORSRuleUnionTypeDef = Union[CORSRuleTypeDef, CORSRuleOutputTypeDef]
CloudFunctionConfigurationUnionTypeDef = Union[
    CloudFunctionConfigurationTypeDef, CloudFunctionConfigurationOutputTypeDef
]

class CompletedMultipartUploadTypeDef(TypedDict):
    Parts: NotRequired[Sequence[CompletedPartTypeDef]]

class CopyObjectOutputTypeDef(TypedDict):
    CopyObjectResult: CopyObjectResultTypeDef
    Expiration: str
    CopySourceVersionId: str
    VersionId: str
    ServerSideEncryption: ServerSideEncryptionType
    SSECustomerAlgorithm: str
    SSECustomerKeyMD5: str
    SSEKMSKeyId: str
    SSEKMSEncryptionContext: str
    BucketKeyEnabled: bool
    RequestCharged: Literal["requester"]
    ResponseMetadata: ResponseMetadataTypeDef

class UploadPartCopyOutputTypeDef(TypedDict):
    CopySourceVersionId: str
    CopyPartResult: CopyPartResultTypeDef
    ServerSideEncryption: ServerSideEncryptionType
    SSECustomerAlgorithm: str
    SSECustomerKeyMD5: str
    SSEKMSKeyId: str
    BucketKeyEnabled: bool
    RequestCharged: Literal["requester"]
    ResponseMetadata: ResponseMetadataTypeDef

class CreateBucketConfigurationTypeDef(TypedDict):
    LocationConstraint: NotRequired[BucketLocationConstraintType]
    Location: NotRequired[LocationInfoTypeDef]
    Bucket: NotRequired[BucketInfoTypeDef]

class CreateSessionOutputTypeDef(TypedDict):
    ServerSideEncryption: ServerSideEncryptionType
    SSEKMSKeyId: str
    SSEKMSEncryptionContext: str
    BucketKeyEnabled: bool
    Credentials: SessionCredentialsTypeDef
    ResponseMetadata: ResponseMetadataTypeDef

class ObjectLockRuleTypeDef(TypedDict):
    DefaultRetention: NotRequired[DefaultRetentionTypeDef]

class DeleteObjectsOutputTypeDef(TypedDict):
    Deleted: List[DeletedObjectTypeDef]
    RequestCharged: Literal["requester"]
    Errors: List[ErrorTypeDef]
    ResponseMetadata: ResponseMetadataTypeDef

class S3KeyFilterOutputTypeDef(TypedDict):
    FilterRules: NotRequired[List[FilterRuleTypeDef]]

class S3KeyFilterTypeDef(TypedDict):
    FilterRules: NotRequired[Sequence[FilterRuleTypeDef]]

class GetBucketPolicyStatusOutputTypeDef(TypedDict):
    PolicyStatus: PolicyStatusTypeDef
    ResponseMetadata: ResponseMetadataTypeDef

class GetObjectAttributesPartsTypeDef(TypedDict):
    TotalPartsCount: NotRequired[int]
    PartNumberMarker: NotRequired[int]
    NextPartNumberMarker: NotRequired[int]
    MaxParts: NotRequired[int]
    IsTruncated: NotRequired[bool]
    Parts: NotRequired[List[ObjectPartTypeDef]]

class GetObjectLegalHoldOutputTypeDef(TypedDict):
    LegalHold: ObjectLockLegalHoldTypeDef
    ResponseMetadata: ResponseMetadataTypeDef

class PutObjectLegalHoldRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    LegalHold: NotRequired[ObjectLockLegalHoldTypeDef]
    RequestPayer: NotRequired[Literal["requester"]]
    VersionId: NotRequired[str]
    ContentMD5: NotRequired[str]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ExpectedBucketOwner: NotRequired[str]

class GetObjectRetentionOutputTypeDef(TypedDict):
    Retention: ObjectLockRetentionOutputTypeDef
    ResponseMetadata: ResponseMetadataTypeDef

class GetPublicAccessBlockOutputTypeDef(TypedDict):
    PublicAccessBlockConfiguration: PublicAccessBlockConfigurationTypeDef
    ResponseMetadata: ResponseMetadataTypeDef

class PutPublicAccessBlockRequestTypeDef(TypedDict):
    Bucket: str
    PublicAccessBlockConfiguration: PublicAccessBlockConfigurationTypeDef
    ContentMD5: NotRequired[str]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ExpectedBucketOwner: NotRequired[str]

class GrantTypeDef(TypedDict):
    Grantee: NotRequired[GranteeTypeDef]
    Permission: NotRequired[PermissionType]

class TargetGrantTypeDef(TypedDict):
    Grantee: NotRequired[GranteeTypeDef]
    Permission: NotRequired[BucketLogsPermissionType]

class HeadBucketRequestWaitExtraTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]
    WaiterConfig: NotRequired[WaiterConfigTypeDef]

class HeadBucketRequestWaitTypeDef(TypedDict):
    Bucket: str
    ExpectedBucketOwner: NotRequired[str]
    WaiterConfig: NotRequired[WaiterConfigTypeDef]

class HeadObjectRequestWaitExtraTypeDef(TypedDict):
    Bucket: str
    Key: str
    IfMatch: NotRequired[str]
    IfModifiedSince: NotRequired[TimestampTypeDef]
    IfNoneMatch: NotRequired[str]
    IfUnmodifiedSince: NotRequired[TimestampTypeDef]
    Range: NotRequired[str]
    ResponseCacheControl: NotRequired[str]
    ResponseContentDisposition: NotRequired[str]
    ResponseContentEncoding: NotRequired[str]
    ResponseContentLanguage: NotRequired[str]
    ResponseContentType: NotRequired[str]
    ResponseExpires: NotRequired[TimestampTypeDef]
    VersionId: NotRequired[str]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]
    RequestPayer: NotRequired[Literal["requester"]]
    PartNumber: NotRequired[int]
    ExpectedBucketOwner: NotRequired[str]
    ChecksumMode: NotRequired[Literal["ENABLED"]]
    WaiterConfig: NotRequired[WaiterConfigTypeDef]

class HeadObjectRequestWaitTypeDef(TypedDict):
    Bucket: str
    Key: str
    IfMatch: NotRequired[str]
    IfModifiedSince: NotRequired[TimestampTypeDef]
    IfNoneMatch: NotRequired[str]
    IfUnmodifiedSince: NotRequired[TimestampTypeDef]
    Range: NotRequired[str]
    ResponseCacheControl: NotRequired[str]
    ResponseContentDisposition: NotRequired[str]
    ResponseContentEncoding: NotRequired[str]
    ResponseContentLanguage: NotRequired[str]
    ResponseContentType: NotRequired[str]
    ResponseExpires: NotRequired[TimestampTypeDef]
    VersionId: NotRequired[str]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]
    RequestPayer: NotRequired[Literal["requester"]]
    PartNumber: NotRequired[int]
    ExpectedBucketOwner: NotRequired[str]
    ChecksumMode: NotRequired[Literal["ENABLED"]]
    WaiterConfig: NotRequired[WaiterConfigTypeDef]

class MultipartUploadTypeDef(TypedDict):
    UploadId: NotRequired[str]
    Key: NotRequired[str]
    Initiated: NotRequired[datetime]
    StorageClass: NotRequired[StorageClassType]
    Owner: NotRequired[OwnerTypeDef]
    Initiator: NotRequired[InitiatorTypeDef]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ChecksumType: NotRequired[ChecksumTypeType]

class InputSerializationTypeDef(TypedDict):
    CSV: NotRequired[CSVInputTypeDef]
    CompressionType: NotRequired[CompressionTypeType]
    JSON: NotRequired[JSONInputTypeDef]
    Parquet: NotRequired[Mapping[str, Any]]

class InventoryEncryptionOutputTypeDef(TypedDict):
    SSES3: NotRequired[Dict[str, Any]]
    SSEKMS: NotRequired[SSEKMSTypeDef]

class InventoryEncryptionTypeDef(TypedDict):
    SSES3: NotRequired[Mapping[str, Any]]
    SSEKMS: NotRequired[SSEKMSTypeDef]

class OutputSerializationTypeDef(TypedDict):
    CSV: NotRequired[CSVOutputTypeDef]
    JSON: NotRequired[JSONOutputTypeDef]

class RuleOutputTypeDef(TypedDict):
    Prefix: str
    Status: ExpirationStatusType
    Expiration: NotRequired[LifecycleExpirationOutputTypeDef]
    ID: NotRequired[str]
    Transition: NotRequired[TransitionOutputTypeDef]
    NoncurrentVersionTransition: NotRequired[NoncurrentVersionTransitionTypeDef]
    NoncurrentVersionExpiration: NotRequired[NoncurrentVersionExpirationTypeDef]
    AbortIncompleteMultipartUpload: NotRequired[AbortIncompleteMultipartUploadTypeDef]

class ListBucketsRequestPaginateTypeDef(TypedDict):
    Prefix: NotRequired[str]
    BucketRegion: NotRequired[str]
    PaginationConfig: NotRequired[PaginatorConfigTypeDef]

class ListDirectoryBucketsRequestPaginateTypeDef(TypedDict):
    PaginationConfig: NotRequired[PaginatorConfigTypeDef]

class ListMultipartUploadsRequestPaginateTypeDef(TypedDict):
    Bucket: str
    Delimiter: NotRequired[str]
    EncodingType: NotRequired[Literal["url"]]
    Prefix: NotRequired[str]
    ExpectedBucketOwner: NotRequired[str]
    RequestPayer: NotRequired[Literal["requester"]]
    PaginationConfig: NotRequired[PaginatorConfigTypeDef]

class ListObjectVersionsRequestPaginateTypeDef(TypedDict):
    Bucket: str
    Delimiter: NotRequired[str]
    EncodingType: NotRequired[Literal["url"]]
    Prefix: NotRequired[str]
    ExpectedBucketOwner: NotRequired[str]
    RequestPayer: NotRequired[Literal["requester"]]
    OptionalObjectAttributes: NotRequired[Sequence[Literal["RestoreStatus"]]]
    PaginationConfig: NotRequired[PaginatorConfigTypeDef]

class ListObjectsRequestPaginateTypeDef(TypedDict):
    Bucket: str
    Delimiter: NotRequired[str]
    EncodingType: NotRequired[Literal["url"]]
    Prefix: NotRequired[str]
    RequestPayer: NotRequired[Literal["requester"]]
    ExpectedBucketOwner: NotRequired[str]
    OptionalObjectAttributes: NotRequired[Sequence[Literal["RestoreStatus"]]]
    PaginationConfig: NotRequired[PaginatorConfigTypeDef]

class ListObjectsV2RequestPaginateTypeDef(TypedDict):
    Bucket: str
    Delimiter: NotRequired[str]
    EncodingType: NotRequired[Literal["url"]]
    Prefix: NotRequired[str]
    FetchOwner: NotRequired[bool]
    StartAfter: NotRequired[str]
    RequestPayer: NotRequired[Literal["requester"]]
    ExpectedBucketOwner: NotRequired[str]
    OptionalObjectAttributes: NotRequired[Sequence[Literal["RestoreStatus"]]]
    PaginationConfig: NotRequired[PaginatorConfigTypeDef]

class ListPartsRequestPaginateTypeDef(TypedDict):
    Bucket: str
    Key: str
    UploadId: str
    RequestPayer: NotRequired[Literal["requester"]]
    ExpectedBucketOwner: NotRequired[str]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]
    PaginationConfig: NotRequired[PaginatorConfigTypeDef]

class ListPartsOutputTypeDef(TypedDict):
    AbortDate: datetime
    AbortRuleId: str
    Bucket: str
    Key: str
    UploadId: str
    PartNumberMarker: int
    NextPartNumberMarker: int
    MaxParts: int
    IsTruncated: bool
    Parts: List[PartTypeDef]
    Initiator: InitiatorTypeDef
    Owner: OwnerTypeDef
    StorageClass: StorageClassType
    RequestCharged: Literal["requester"]
    ChecksumAlgorithm: ChecksumAlgorithmType
    ChecksumType: ChecksumTypeType
    ResponseMetadata: ResponseMetadataTypeDef

class MetadataTableConfigurationResultTypeDef(TypedDict):
    S3TablesDestinationResult: S3TablesDestinationResultTypeDef

class MetadataTableConfigurationTypeDef(TypedDict):
    S3TablesDestination: S3TablesDestinationTypeDef

class MetricsTypeDef(TypedDict):
    Status: MetricsStatusType
    EventThreshold: NotRequired[ReplicationTimeValueTypeDef]

class ReplicationTimeTypeDef(TypedDict):
    Status: ReplicationTimeStatusType
    Time: ReplicationTimeValueTypeDef

class NotificationConfigurationDeprecatedResponseTypeDef(TypedDict):
    TopicConfiguration: TopicConfigurationDeprecatedOutputTypeDef
    QueueConfiguration: QueueConfigurationDeprecatedOutputTypeDef
    CloudFunctionConfiguration: CloudFunctionConfigurationOutputTypeDef
    ResponseMetadata: ResponseMetadataTypeDef

class ObjectTypeDef(TypedDict):
    Key: NotRequired[str]
    LastModified: NotRequired[datetime]
    ETag: NotRequired[str]
    ChecksumAlgorithm: NotRequired[List[ChecksumAlgorithmType]]
    ChecksumType: NotRequired[ChecksumTypeType]
    Size: NotRequired[int]
    StorageClass: NotRequired[ObjectStorageClassType]
    Owner: NotRequired[OwnerTypeDef]
    RestoreStatus: NotRequired[RestoreStatusTypeDef]

class ObjectVersionTypeDef(TypedDict):
    ETag: NotRequired[str]
    ChecksumAlgorithm: NotRequired[List[ChecksumAlgorithmType]]
    ChecksumType: NotRequired[ChecksumTypeType]
    Size: NotRequired[int]
    StorageClass: NotRequired[Literal["STANDARD"]]
    Key: NotRequired[str]
    VersionId: NotRequired[str]
    IsLatest: NotRequired[bool]
    LastModified: NotRequired[datetime]
    Owner: NotRequired[OwnerTypeDef]
    RestoreStatus: NotRequired[RestoreStatusTypeDef]

class OwnershipControlsOutputTypeDef(TypedDict):
    Rules: List[OwnershipControlsRuleTypeDef]

class OwnershipControlsTypeDef(TypedDict):
    Rules: Sequence[OwnershipControlsRuleTypeDef]

class TargetObjectKeyFormatOutputTypeDef(TypedDict):
    SimplePrefix: NotRequired[Dict[str, Any]]
    PartitionedPrefix: NotRequired[PartitionedPrefixTypeDef]

class TargetObjectKeyFormatTypeDef(TypedDict):
    SimplePrefix: NotRequired[Mapping[str, Any]]
    PartitionedPrefix: NotRequired[PartitionedPrefixTypeDef]

class ProgressEventTypeDef(TypedDict):
    Details: NotRequired[ProgressTypeDef]

class PutBucketRequestPaymentRequestBucketRequestPaymentPutTypeDef(TypedDict):
    RequestPaymentConfiguration: RequestPaymentConfigurationTypeDef
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ExpectedBucketOwner: NotRequired[str]

class PutBucketRequestPaymentRequestTypeDef(TypedDict):
    Bucket: str
    RequestPaymentConfiguration: RequestPaymentConfigurationTypeDef
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ExpectedBucketOwner: NotRequired[str]

class PutBucketVersioningRequestBucketVersioningPutTypeDef(TypedDict):
    VersioningConfiguration: VersioningConfigurationTypeDef
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    MFA: NotRequired[str]
    ExpectedBucketOwner: NotRequired[str]

class PutBucketVersioningRequestTypeDef(TypedDict):
    Bucket: str
    VersioningConfiguration: VersioningConfigurationTypeDef
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    MFA: NotRequired[str]
    ExpectedBucketOwner: NotRequired[str]

QueueConfigurationDeprecatedUnionTypeDef = Union[
    QueueConfigurationDeprecatedTypeDef, QueueConfigurationDeprecatedOutputTypeDef
]

class RoutingRuleTypeDef(TypedDict):
    Redirect: RedirectTypeDef
    Condition: NotRequired[ConditionTypeDef]

class ServerSideEncryptionRuleTypeDef(TypedDict):
    ApplyServerSideEncryptionByDefault: NotRequired[ServerSideEncryptionByDefaultTypeDef]
    BucketKeyEnabled: NotRequired[bool]

class SourceSelectionCriteriaTypeDef(TypedDict):
    SseKmsEncryptedObjects: NotRequired[SseKmsEncryptedObjectsTypeDef]
    ReplicaModifications: NotRequired[ReplicaModificationsTypeDef]

class StatsEventTypeDef(TypedDict):
    Details: NotRequired[StatsTypeDef]

TopicConfigurationDeprecatedUnionTypeDef = Union[
    TopicConfigurationDeprecatedTypeDef, TopicConfigurationDeprecatedOutputTypeDef
]
LifecycleExpirationUnionTypeDef = Union[
    LifecycleExpirationTypeDef, LifecycleExpirationOutputTypeDef
]

class DeleteTypeDef(TypedDict):
    Objects: Sequence[ObjectIdentifierTypeDef]
    Quiet: NotRequired[bool]

ObjectLockRetentionUnionTypeDef = Union[
    ObjectLockRetentionTypeDef, ObjectLockRetentionOutputTypeDef
]
TransitionUnionTypeDef = Union[TransitionTypeDef, TransitionOutputTypeDef]

class AnalyticsFilterOutputTypeDef(TypedDict):
    Prefix: NotRequired[str]
    Tag: NotRequired[TagTypeDef]
    And: NotRequired[AnalyticsAndOperatorOutputTypeDef]

class AnalyticsFilterTypeDef(TypedDict):
    Prefix: NotRequired[str]
    Tag: NotRequired[TagTypeDef]
    And: NotRequired[AnalyticsAndOperatorTypeDef]

class IntelligentTieringFilterOutputTypeDef(TypedDict):
    Prefix: NotRequired[str]
    Tag: NotRequired[TagTypeDef]
    And: NotRequired[IntelligentTieringAndOperatorOutputTypeDef]

class IntelligentTieringFilterTypeDef(TypedDict):
    Prefix: NotRequired[str]
    Tag: NotRequired[TagTypeDef]
    And: NotRequired[IntelligentTieringAndOperatorTypeDef]

class LifecycleRuleFilterOutputTypeDef(TypedDict):
    Prefix: NotRequired[str]
    Tag: NotRequired[TagTypeDef]
    ObjectSizeGreaterThan: NotRequired[int]
    ObjectSizeLessThan: NotRequired[int]
    And: NotRequired[LifecycleRuleAndOperatorOutputTypeDef]

LifecycleRuleAndOperatorUnionTypeDef = Union[
    LifecycleRuleAndOperatorTypeDef, LifecycleRuleAndOperatorOutputTypeDef
]

class MetricsFilterOutputTypeDef(TypedDict):
    Prefix: NotRequired[str]
    Tag: NotRequired[TagTypeDef]
    AccessPointArn: NotRequired[str]
    And: NotRequired[MetricsAndOperatorOutputTypeDef]

class MetricsFilterTypeDef(TypedDict):
    Prefix: NotRequired[str]
    Tag: NotRequired[TagTypeDef]
    AccessPointArn: NotRequired[str]
    And: NotRequired[MetricsAndOperatorTypeDef]

class ReplicationRuleFilterOutputTypeDef(TypedDict):
    Prefix: NotRequired[str]
    Tag: NotRequired[TagTypeDef]
    And: NotRequired[ReplicationRuleAndOperatorOutputTypeDef]

class ReplicationRuleFilterTypeDef(TypedDict):
    Prefix: NotRequired[str]
    Tag: NotRequired[TagTypeDef]
    And: NotRequired[ReplicationRuleAndOperatorTypeDef]

class PutBucketTaggingRequestBucketTaggingPutTypeDef(TypedDict):
    Tagging: TaggingTypeDef
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ExpectedBucketOwner: NotRequired[str]

class PutBucketTaggingRequestTypeDef(TypedDict):
    Bucket: str
    Tagging: TaggingTypeDef
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ExpectedBucketOwner: NotRequired[str]

class PutObjectTaggingRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    Tagging: TaggingTypeDef
    VersionId: NotRequired[str]
    ContentMD5: NotRequired[str]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ExpectedBucketOwner: NotRequired[str]
    RequestPayer: NotRequired[Literal["requester"]]

class StorageClassAnalysisDataExportTypeDef(TypedDict):
    OutputSchemaVersion: Literal["V_1"]
    Destination: AnalyticsExportDestinationTypeDef

class CopyObjectRequestObjectCopyFromTypeDef(TypedDict):
    CopySource: CopySourceOrStrTypeDef
    ACL: NotRequired[ObjectCannedACLType]
    CacheControl: NotRequired[str]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ContentDisposition: NotRequired[str]
    ContentEncoding: NotRequired[str]
    ContentLanguage: NotRequired[str]
    ContentType: NotRequired[str]
    CopySourceIfMatch: NotRequired[str]
    CopySourceIfModifiedSince: NotRequired[TimestampTypeDef]
    CopySourceIfNoneMatch: NotRequired[str]
    CopySourceIfUnmodifiedSince: NotRequired[TimestampTypeDef]
    Expires: NotRequired[TimestampTypeDef]
    GrantFullControl: NotRequired[str]
    GrantRead: NotRequired[str]
    GrantReadACP: NotRequired[str]
    GrantWriteACP: NotRequired[str]
    Metadata: NotRequired[Mapping[str, str]]
    MetadataDirective: NotRequired[MetadataDirectiveType]
    TaggingDirective: NotRequired[TaggingDirectiveType]
    ServerSideEncryption: NotRequired[ServerSideEncryptionType]
    StorageClass: NotRequired[StorageClassType]
    WebsiteRedirectLocation: NotRequired[str]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]
    SSEKMSKeyId: NotRequired[str]
    SSEKMSEncryptionContext: NotRequired[str]
    BucketKeyEnabled: NotRequired[bool]
    CopySourceSSECustomerAlgorithm: NotRequired[str]
    CopySourceSSECustomerKey: NotRequired[str | bytes]
    RequestPayer: NotRequired[Literal["requester"]]
    Tagging: NotRequired[str]
    ObjectLockMode: NotRequired[ObjectLockModeType]
    ObjectLockRetainUntilDate: NotRequired[TimestampTypeDef]
    ObjectLockLegalHoldStatus: NotRequired[ObjectLockLegalHoldStatusType]
    ExpectedBucketOwner: NotRequired[str]
    ExpectedSourceBucketOwner: NotRequired[str]

class CopyObjectRequestObjectSummaryCopyFromTypeDef(TypedDict):
    CopySource: CopySourceOrStrTypeDef
    ACL: NotRequired[ObjectCannedACLType]
    CacheControl: NotRequired[str]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ContentDisposition: NotRequired[str]
    ContentEncoding: NotRequired[str]
    ContentLanguage: NotRequired[str]
    ContentType: NotRequired[str]
    CopySourceIfMatch: NotRequired[str]
    CopySourceIfModifiedSince: NotRequired[TimestampTypeDef]
    CopySourceIfNoneMatch: NotRequired[str]
    CopySourceIfUnmodifiedSince: NotRequired[TimestampTypeDef]
    Expires: NotRequired[TimestampTypeDef]
    GrantFullControl: NotRequired[str]
    GrantRead: NotRequired[str]
    GrantReadACP: NotRequired[str]
    GrantWriteACP: NotRequired[str]
    Metadata: NotRequired[Mapping[str, str]]
    MetadataDirective: NotRequired[MetadataDirectiveType]
    TaggingDirective: NotRequired[TaggingDirectiveType]
    ServerSideEncryption: NotRequired[ServerSideEncryptionType]
    StorageClass: NotRequired[StorageClassType]
    WebsiteRedirectLocation: NotRequired[str]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]
    SSEKMSKeyId: NotRequired[str]
    SSEKMSEncryptionContext: NotRequired[str]
    BucketKeyEnabled: NotRequired[bool]
    CopySourceSSECustomerAlgorithm: NotRequired[str]
    CopySourceSSECustomerKey: NotRequired[str | bytes]
    RequestPayer: NotRequired[Literal["requester"]]
    Tagging: NotRequired[str]
    ObjectLockMode: NotRequired[ObjectLockModeType]
    ObjectLockRetainUntilDate: NotRequired[TimestampTypeDef]
    ObjectLockLegalHoldStatus: NotRequired[ObjectLockLegalHoldStatusType]
    ExpectedBucketOwner: NotRequired[str]
    ExpectedSourceBucketOwner: NotRequired[str]

class CopyObjectRequestTypeDef(TypedDict):
    Bucket: str
    CopySource: CopySourceOrStrTypeDef
    Key: str
    ACL: NotRequired[ObjectCannedACLType]
    CacheControl: NotRequired[str]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ContentDisposition: NotRequired[str]
    ContentEncoding: NotRequired[str]
    ContentLanguage: NotRequired[str]
    ContentType: NotRequired[str]
    CopySourceIfMatch: NotRequired[str]
    CopySourceIfModifiedSince: NotRequired[TimestampTypeDef]
    CopySourceIfNoneMatch: NotRequired[str]
    CopySourceIfUnmodifiedSince: NotRequired[TimestampTypeDef]
    Expires: NotRequired[TimestampTypeDef]
    GrantFullControl: NotRequired[str]
    GrantRead: NotRequired[str]
    GrantReadACP: NotRequired[str]
    GrantWriteACP: NotRequired[str]
    Metadata: NotRequired[Mapping[str, str]]
    MetadataDirective: NotRequired[MetadataDirectiveType]
    TaggingDirective: NotRequired[TaggingDirectiveType]
    ServerSideEncryption: NotRequired[ServerSideEncryptionType]
    StorageClass: NotRequired[StorageClassType]
    WebsiteRedirectLocation: NotRequired[str]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]
    SSEKMSKeyId: NotRequired[str]
    SSEKMSEncryptionContext: NotRequired[str]
    BucketKeyEnabled: NotRequired[bool]
    CopySourceSSECustomerAlgorithm: NotRequired[str]
    CopySourceSSECustomerKey: NotRequired[str | bytes]
    RequestPayer: NotRequired[Literal["requester"]]
    Tagging: NotRequired[str]
    ObjectLockMode: NotRequired[ObjectLockModeType]
    ObjectLockRetainUntilDate: NotRequired[TimestampTypeDef]
    ObjectLockLegalHoldStatus: NotRequired[ObjectLockLegalHoldStatusType]
    ExpectedBucketOwner: NotRequired[str]
    ExpectedSourceBucketOwner: NotRequired[str]

class UploadPartCopyRequestMultipartUploadPartCopyFromTypeDef(TypedDict):
    CopySource: CopySourceOrStrTypeDef
    CopySourceIfMatch: NotRequired[str]
    CopySourceIfModifiedSince: NotRequired[TimestampTypeDef]
    CopySourceIfNoneMatch: NotRequired[str]
    CopySourceIfUnmodifiedSince: NotRequired[TimestampTypeDef]
    CopySourceRange: NotRequired[str]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]
    CopySourceSSECustomerAlgorithm: NotRequired[str]
    CopySourceSSECustomerKey: NotRequired[str | bytes]
    RequestPayer: NotRequired[Literal["requester"]]
    ExpectedBucketOwner: NotRequired[str]
    ExpectedSourceBucketOwner: NotRequired[str]

class UploadPartCopyRequestTypeDef(TypedDict):
    Bucket: str
    CopySource: CopySourceOrStrTypeDef
    Key: str
    PartNumber: int
    UploadId: str
    CopySourceIfMatch: NotRequired[str]
    CopySourceIfModifiedSince: NotRequired[TimestampTypeDef]
    CopySourceIfNoneMatch: NotRequired[str]
    CopySourceIfUnmodifiedSince: NotRequired[TimestampTypeDef]
    CopySourceRange: NotRequired[str]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]
    CopySourceSSECustomerAlgorithm: NotRequired[str]
    CopySourceSSECustomerKey: NotRequired[str | bytes]
    RequestPayer: NotRequired[Literal["requester"]]
    ExpectedBucketOwner: NotRequired[str]
    ExpectedSourceBucketOwner: NotRequired[str]

class CORSConfigurationTypeDef(TypedDict):
    CORSRules: Sequence[CORSRuleUnionTypeDef]

class CompleteMultipartUploadRequestMultipartUploadCompleteTypeDef(TypedDict):
    MultipartUpload: NotRequired[CompletedMultipartUploadTypeDef]
    ChecksumCRC32: NotRequired[str]
    ChecksumCRC32C: NotRequired[str]
    ChecksumCRC64NVME: NotRequired[str]
    ChecksumSHA1: NotRequired[str]
    ChecksumSHA256: NotRequired[str]
    ChecksumType: NotRequired[ChecksumTypeType]
    MpuObjectSize: NotRequired[int]
    RequestPayer: NotRequired[Literal["requester"]]
    ExpectedBucketOwner: NotRequired[str]
    IfMatch: NotRequired[str]
    IfNoneMatch: NotRequired[str]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]

class CompleteMultipartUploadRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    UploadId: str
    MultipartUpload: NotRequired[CompletedMultipartUploadTypeDef]
    ChecksumCRC32: NotRequired[str]
    ChecksumCRC32C: NotRequired[str]
    ChecksumCRC64NVME: NotRequired[str]
    ChecksumSHA1: NotRequired[str]
    ChecksumSHA256: NotRequired[str]
    ChecksumType: NotRequired[ChecksumTypeType]
    MpuObjectSize: NotRequired[int]
    RequestPayer: NotRequired[Literal["requester"]]
    ExpectedBucketOwner: NotRequired[str]
    IfMatch: NotRequired[str]
    IfNoneMatch: NotRequired[str]
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]

class CreateBucketRequestBucketCreateTypeDef(TypedDict):
    ACL: NotRequired[BucketCannedACLType]
    CreateBucketConfiguration: NotRequired[CreateBucketConfigurationTypeDef]
    GrantFullControl: NotRequired[str]
    GrantRead: NotRequired[str]
    GrantReadACP: NotRequired[str]
    GrantWrite: NotRequired[str]
    GrantWriteACP: NotRequired[str]
    ObjectLockEnabledForBucket: NotRequired[bool]
    ObjectOwnership: NotRequired[ObjectOwnershipType]

class CreateBucketRequestServiceResourceCreateBucketTypeDef(TypedDict):
    Bucket: str
    ACL: NotRequired[BucketCannedACLType]
    CreateBucketConfiguration: NotRequired[CreateBucketConfigurationTypeDef]
    GrantFullControl: NotRequired[str]
    GrantRead: NotRequired[str]
    GrantReadACP: NotRequired[str]
    GrantWrite: NotRequired[str]
    GrantWriteACP: NotRequired[str]
    ObjectLockEnabledForBucket: NotRequired[bool]
    ObjectOwnership: NotRequired[ObjectOwnershipType]

class CreateBucketRequestTypeDef(TypedDict):
    Bucket: str
    ACL: NotRequired[BucketCannedACLType]
    CreateBucketConfiguration: NotRequired[CreateBucketConfigurationTypeDef]
    GrantFullControl: NotRequired[str]
    GrantRead: NotRequired[str]
    GrantReadACP: NotRequired[str]
    GrantWrite: NotRequired[str]
    GrantWriteACP: NotRequired[str]
    ObjectLockEnabledForBucket: NotRequired[bool]
    ObjectOwnership: NotRequired[ObjectOwnershipType]

class ObjectLockConfigurationTypeDef(TypedDict):
    ObjectLockEnabled: NotRequired[Literal["Enabled"]]
    Rule: NotRequired[ObjectLockRuleTypeDef]

class NotificationConfigurationFilterOutputTypeDef(TypedDict):
    Key: NotRequired[S3KeyFilterOutputTypeDef]

S3KeyFilterUnionTypeDef = Union[S3KeyFilterTypeDef, S3KeyFilterOutputTypeDef]

class GetObjectAttributesOutputTypeDef(TypedDict):
    DeleteMarker: bool
    LastModified: datetime
    VersionId: str
    RequestCharged: Literal["requester"]
    ETag: str
    Checksum: ChecksumTypeDef
    ObjectParts: GetObjectAttributesPartsTypeDef
    StorageClass: StorageClassType
    ObjectSize: int
    ResponseMetadata: ResponseMetadataTypeDef

class AccessControlPolicyTypeDef(TypedDict):
    Grants: NotRequired[Sequence[GrantTypeDef]]
    Owner: NotRequired[OwnerTypeDef]

class GetBucketAclOutputTypeDef(TypedDict):
    Owner: OwnerTypeDef
    Grants: List[GrantTypeDef]
    ResponseMetadata: ResponseMetadataTypeDef

class GetObjectAclOutputTypeDef(TypedDict):
    Owner: OwnerTypeDef
    Grants: List[GrantTypeDef]
    RequestCharged: Literal["requester"]
    ResponseMetadata: ResponseMetadataTypeDef

class S3LocationTypeDef(TypedDict):
    BucketName: str
    Prefix: str
    Encryption: NotRequired[EncryptionTypeDef]
    CannedACL: NotRequired[ObjectCannedACLType]
    AccessControlList: NotRequired[Sequence[GrantTypeDef]]
    Tagging: NotRequired[TaggingTypeDef]
    UserMetadata: NotRequired[Sequence[MetadataEntryTypeDef]]
    StorageClass: NotRequired[StorageClassType]

class ListMultipartUploadsOutputTypeDef(TypedDict):
    Bucket: str
    KeyMarker: str
    UploadIdMarker: str
    NextKeyMarker: str
    Prefix: str
    Delimiter: str
    NextUploadIdMarker: str
    MaxUploads: int
    IsTruncated: bool
    Uploads: List[MultipartUploadTypeDef]
    EncodingType: Literal["url"]
    RequestCharged: Literal["requester"]
    ResponseMetadata: ResponseMetadataTypeDef
    CommonPrefixes: NotRequired[List[CommonPrefixTypeDef]]

class InventoryS3BucketDestinationOutputTypeDef(TypedDict):
    Bucket: str
    Format: InventoryFormatType
    AccountId: NotRequired[str]
    Prefix: NotRequired[str]
    Encryption: NotRequired[InventoryEncryptionOutputTypeDef]

class InventoryS3BucketDestinationTypeDef(TypedDict):
    Bucket: str
    Format: InventoryFormatType
    AccountId: NotRequired[str]
    Prefix: NotRequired[str]
    Encryption: NotRequired[InventoryEncryptionTypeDef]

class SelectObjectContentRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    Expression: str
    ExpressionType: Literal["SQL"]
    InputSerialization: InputSerializationTypeDef
    OutputSerialization: OutputSerializationTypeDef
    SSECustomerAlgorithm: NotRequired[str]
    SSECustomerKey: NotRequired[str | bytes]
    RequestProgress: NotRequired[RequestProgressTypeDef]
    ScanRange: NotRequired[ScanRangeTypeDef]
    ExpectedBucketOwner: NotRequired[str]

class SelectParametersTypeDef(TypedDict):
    InputSerialization: InputSerializationTypeDef
    ExpressionType: Literal["SQL"]
    Expression: str
    OutputSerialization: OutputSerializationTypeDef

class GetBucketLifecycleOutputTypeDef(TypedDict):
    Rules: List[RuleOutputTypeDef]
    ResponseMetadata: ResponseMetadataTypeDef

class GetBucketMetadataTableConfigurationResultTypeDef(TypedDict):
    MetadataTableConfigurationResult: MetadataTableConfigurationResultTypeDef
    Status: str
    Error: NotRequired[ErrorDetailsTypeDef]

class CreateBucketMetadataTableConfigurationRequestTypeDef(TypedDict):
    Bucket: str
    MetadataTableConfiguration: MetadataTableConfigurationTypeDef
    ContentMD5: NotRequired[str]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ExpectedBucketOwner: NotRequired[str]

class DestinationTypeDef(TypedDict):
    Bucket: str
    Account: NotRequired[str]
    StorageClass: NotRequired[StorageClassType]
    AccessControlTranslation: NotRequired[AccessControlTranslationTypeDef]
    EncryptionConfiguration: NotRequired[EncryptionConfigurationTypeDef]
    ReplicationTime: NotRequired[ReplicationTimeTypeDef]
    Metrics: NotRequired[MetricsTypeDef]

class ListObjectsOutputTypeDef(TypedDict):
    IsTruncated: bool
    Marker: str
    NextMarker: str
    Name: str
    Prefix: str
    Delimiter: str
    MaxKeys: int
    EncodingType: Literal["url"]
    RequestCharged: Literal["requester"]
    ResponseMetadata: ResponseMetadataTypeDef
    Contents: NotRequired[List[ObjectTypeDef]]
    CommonPrefixes: NotRequired[List[CommonPrefixTypeDef]]

class ListObjectsV2OutputTypeDef(TypedDict):
    IsTruncated: bool
    Name: str
    Prefix: str
    Delimiter: str
    MaxKeys: int
    EncodingType: Literal["url"]
    KeyCount: int
    ContinuationToken: str
    NextContinuationToken: str
    StartAfter: str
    RequestCharged: Literal["requester"]
    ResponseMetadata: ResponseMetadataTypeDef
    Contents: NotRequired[List[ObjectTypeDef]]
    CommonPrefixes: NotRequired[List[CommonPrefixTypeDef]]

class ListObjectVersionsOutputTypeDef(TypedDict):
    IsTruncated: bool
    KeyMarker: str
    VersionIdMarker: str
    NextKeyMarker: str
    NextVersionIdMarker: str
    Versions: List[ObjectVersionTypeDef]
    DeleteMarkers: List[DeleteMarkerEntryTypeDef]
    Name: str
    Prefix: str
    Delimiter: str
    MaxKeys: int
    EncodingType: Literal["url"]
    RequestCharged: Literal["requester"]
    ResponseMetadata: ResponseMetadataTypeDef
    CommonPrefixes: NotRequired[List[CommonPrefixTypeDef]]

class GetBucketOwnershipControlsOutputTypeDef(TypedDict):
    OwnershipControls: OwnershipControlsOutputTypeDef
    ResponseMetadata: ResponseMetadataTypeDef

OwnershipControlsUnionTypeDef = Union[OwnershipControlsTypeDef, OwnershipControlsOutputTypeDef]

class LoggingEnabledOutputTypeDef(TypedDict):
    TargetBucket: str
    TargetPrefix: str
    TargetGrants: NotRequired[List[TargetGrantTypeDef]]
    TargetObjectKeyFormat: NotRequired[TargetObjectKeyFormatOutputTypeDef]

TargetObjectKeyFormatUnionTypeDef = Union[
    TargetObjectKeyFormatTypeDef, TargetObjectKeyFormatOutputTypeDef
]

class GetBucketWebsiteOutputTypeDef(TypedDict):
    RedirectAllRequestsTo: RedirectAllRequestsToTypeDef
    IndexDocument: IndexDocumentTypeDef
    ErrorDocument: ErrorDocumentTypeDef
    RoutingRules: List[RoutingRuleTypeDef]
    ResponseMetadata: ResponseMetadataTypeDef

class WebsiteConfigurationTypeDef(TypedDict):
    ErrorDocument: NotRequired[ErrorDocumentTypeDef]
    IndexDocument: NotRequired[IndexDocumentTypeDef]
    RedirectAllRequestsTo: NotRequired[RedirectAllRequestsToTypeDef]
    RoutingRules: NotRequired[Sequence[RoutingRuleTypeDef]]

class ServerSideEncryptionConfigurationOutputTypeDef(TypedDict):
    Rules: List[ServerSideEncryptionRuleTypeDef]

class ServerSideEncryptionConfigurationTypeDef(TypedDict):
    Rules: Sequence[ServerSideEncryptionRuleTypeDef]

class SelectObjectContentEventStreamTypeDef(TypedDict):
    Records: NotRequired[RecordsEventTypeDef]
    Stats: NotRequired[StatsEventTypeDef]
    Progress: NotRequired[ProgressEventTypeDef]
    Cont: NotRequired[Dict[str, Any]]
    End: NotRequired[Dict[str, Any]]

class NotificationConfigurationDeprecatedTypeDef(TypedDict):
    TopicConfiguration: NotRequired[TopicConfigurationDeprecatedUnionTypeDef]
    QueueConfiguration: NotRequired[QueueConfigurationDeprecatedUnionTypeDef]
    CloudFunctionConfiguration: NotRequired[CloudFunctionConfigurationUnionTypeDef]

class DeleteObjectsRequestBucketDeleteObjectsTypeDef(TypedDict):
    Delete: DeleteTypeDef
    MFA: NotRequired[str]
    RequestPayer: NotRequired[Literal["requester"]]
    BypassGovernanceRetention: NotRequired[bool]
    ExpectedBucketOwner: NotRequired[str]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]

class DeleteObjectsRequestTypeDef(TypedDict):
    Bucket: str
    Delete: DeleteTypeDef
    MFA: NotRequired[str]
    RequestPayer: NotRequired[Literal["requester"]]
    BypassGovernanceRetention: NotRequired[bool]
    ExpectedBucketOwner: NotRequired[str]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]

class PutObjectRetentionRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    Retention: NotRequired[ObjectLockRetentionUnionTypeDef]
    RequestPayer: NotRequired[Literal["requester"]]
    VersionId: NotRequired[str]
    BypassGovernanceRetention: NotRequired[bool]
    ContentMD5: NotRequired[str]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ExpectedBucketOwner: NotRequired[str]

class RuleTypeDef(TypedDict):
    Prefix: str
    Status: ExpirationStatusType
    Expiration: NotRequired[LifecycleExpirationUnionTypeDef]
    ID: NotRequired[str]
    Transition: NotRequired[TransitionUnionTypeDef]
    NoncurrentVersionTransition: NotRequired[NoncurrentVersionTransitionTypeDef]
    NoncurrentVersionExpiration: NotRequired[NoncurrentVersionExpirationTypeDef]
    AbortIncompleteMultipartUpload: NotRequired[AbortIncompleteMultipartUploadTypeDef]

class IntelligentTieringConfigurationOutputTypeDef(TypedDict):
    Id: str
    Status: IntelligentTieringStatusType
    Tierings: List[TieringTypeDef]
    Filter: NotRequired[IntelligentTieringFilterOutputTypeDef]

class IntelligentTieringConfigurationTypeDef(TypedDict):
    Id: str
    Status: IntelligentTieringStatusType
    Tierings: Sequence[TieringTypeDef]
    Filter: NotRequired[IntelligentTieringFilterTypeDef]

class LifecycleRuleOutputTypeDef(TypedDict):
    Status: ExpirationStatusType
    Expiration: NotRequired[LifecycleExpirationOutputTypeDef]
    ID: NotRequired[str]
    Prefix: NotRequired[str]
    Filter: NotRequired[LifecycleRuleFilterOutputTypeDef]
    Transitions: NotRequired[List[TransitionOutputTypeDef]]
    NoncurrentVersionTransitions: NotRequired[List[NoncurrentVersionTransitionTypeDef]]
    NoncurrentVersionExpiration: NotRequired[NoncurrentVersionExpirationTypeDef]
    AbortIncompleteMultipartUpload: NotRequired[AbortIncompleteMultipartUploadTypeDef]

class LifecycleRuleFilterTypeDef(TypedDict):
    Prefix: NotRequired[str]
    Tag: NotRequired[TagTypeDef]
    ObjectSizeGreaterThan: NotRequired[int]
    ObjectSizeLessThan: NotRequired[int]
    And: NotRequired[LifecycleRuleAndOperatorUnionTypeDef]

class MetricsConfigurationOutputTypeDef(TypedDict):
    Id: str
    Filter: NotRequired[MetricsFilterOutputTypeDef]

class MetricsConfigurationTypeDef(TypedDict):
    Id: str
    Filter: NotRequired[MetricsFilterTypeDef]

class StorageClassAnalysisTypeDef(TypedDict):
    DataExport: NotRequired[StorageClassAnalysisDataExportTypeDef]

class PutBucketCorsRequestBucketCorsPutTypeDef(TypedDict):
    CORSConfiguration: CORSConfigurationTypeDef
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ExpectedBucketOwner: NotRequired[str]

class PutBucketCorsRequestTypeDef(TypedDict):
    Bucket: str
    CORSConfiguration: CORSConfigurationTypeDef
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ExpectedBucketOwner: NotRequired[str]

class GetObjectLockConfigurationOutputTypeDef(TypedDict):
    ObjectLockConfiguration: ObjectLockConfigurationTypeDef
    ResponseMetadata: ResponseMetadataTypeDef

class PutObjectLockConfigurationRequestTypeDef(TypedDict):
    Bucket: str
    ObjectLockConfiguration: NotRequired[ObjectLockConfigurationTypeDef]
    RequestPayer: NotRequired[Literal["requester"]]
    Token: NotRequired[str]
    ContentMD5: NotRequired[str]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ExpectedBucketOwner: NotRequired[str]

class LambdaFunctionConfigurationOutputTypeDef(TypedDict):
    LambdaFunctionArn: str
    Events: List[EventType]
    Id: NotRequired[str]
    Filter: NotRequired[NotificationConfigurationFilterOutputTypeDef]

class QueueConfigurationOutputTypeDef(TypedDict):
    QueueArn: str
    Events: List[EventType]
    Id: NotRequired[str]
    Filter: NotRequired[NotificationConfigurationFilterOutputTypeDef]

class TopicConfigurationOutputTypeDef(TypedDict):
    TopicArn: str
    Events: List[EventType]
    Id: NotRequired[str]
    Filter: NotRequired[NotificationConfigurationFilterOutputTypeDef]

class NotificationConfigurationFilterTypeDef(TypedDict):
    Key: NotRequired[S3KeyFilterUnionTypeDef]

class PutBucketAclRequestBucketAclPutTypeDef(TypedDict):
    ACL: NotRequired[BucketCannedACLType]
    AccessControlPolicy: NotRequired[AccessControlPolicyTypeDef]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    GrantFullControl: NotRequired[str]
    GrantRead: NotRequired[str]
    GrantReadACP: NotRequired[str]
    GrantWrite: NotRequired[str]
    GrantWriteACP: NotRequired[str]
    ExpectedBucketOwner: NotRequired[str]

class PutBucketAclRequestTypeDef(TypedDict):
    Bucket: str
    ACL: NotRequired[BucketCannedACLType]
    AccessControlPolicy: NotRequired[AccessControlPolicyTypeDef]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    GrantFullControl: NotRequired[str]
    GrantRead: NotRequired[str]
    GrantReadACP: NotRequired[str]
    GrantWrite: NotRequired[str]
    GrantWriteACP: NotRequired[str]
    ExpectedBucketOwner: NotRequired[str]

class PutObjectAclRequestObjectAclPutTypeDef(TypedDict):
    ACL: NotRequired[ObjectCannedACLType]
    AccessControlPolicy: NotRequired[AccessControlPolicyTypeDef]
    ContentMD5: NotRequired[str]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    GrantFullControl: NotRequired[str]
    GrantRead: NotRequired[str]
    GrantReadACP: NotRequired[str]
    GrantWrite: NotRequired[str]
    GrantWriteACP: NotRequired[str]
    RequestPayer: NotRequired[Literal["requester"]]
    VersionId: NotRequired[str]
    ExpectedBucketOwner: NotRequired[str]

class PutObjectAclRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    ACL: NotRequired[ObjectCannedACLType]
    AccessControlPolicy: NotRequired[AccessControlPolicyTypeDef]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    GrantFullControl: NotRequired[str]
    GrantRead: NotRequired[str]
    GrantReadACP: NotRequired[str]
    GrantWrite: NotRequired[str]
    GrantWriteACP: NotRequired[str]
    RequestPayer: NotRequired[Literal["requester"]]
    VersionId: NotRequired[str]
    ExpectedBucketOwner: NotRequired[str]

class OutputLocationTypeDef(TypedDict):
    S3: NotRequired[S3LocationTypeDef]

class InventoryDestinationOutputTypeDef(TypedDict):
    S3BucketDestination: InventoryS3BucketDestinationOutputTypeDef

class InventoryDestinationTypeDef(TypedDict):
    S3BucketDestination: InventoryS3BucketDestinationTypeDef

class GetBucketMetadataTableConfigurationOutputTypeDef(TypedDict):
    GetBucketMetadataTableConfigurationResult: GetBucketMetadataTableConfigurationResultTypeDef
    ResponseMetadata: ResponseMetadataTypeDef

class ReplicationRuleOutputTypeDef(TypedDict):
    Status: ReplicationRuleStatusType
    Destination: DestinationTypeDef
    ID: NotRequired[str]
    Priority: NotRequired[int]
    Prefix: NotRequired[str]
    Filter: NotRequired[ReplicationRuleFilterOutputTypeDef]
    SourceSelectionCriteria: NotRequired[SourceSelectionCriteriaTypeDef]
    ExistingObjectReplication: NotRequired[ExistingObjectReplicationTypeDef]
    DeleteMarkerReplication: NotRequired[DeleteMarkerReplicationTypeDef]

class ReplicationRuleTypeDef(TypedDict):
    Status: ReplicationRuleStatusType
    Destination: DestinationTypeDef
    ID: NotRequired[str]
    Priority: NotRequired[int]
    Prefix: NotRequired[str]
    Filter: NotRequired[ReplicationRuleFilterTypeDef]
    SourceSelectionCriteria: NotRequired[SourceSelectionCriteriaTypeDef]
    ExistingObjectReplication: NotRequired[ExistingObjectReplicationTypeDef]
    DeleteMarkerReplication: NotRequired[DeleteMarkerReplicationTypeDef]

class PutBucketOwnershipControlsRequestTypeDef(TypedDict):
    Bucket: str
    OwnershipControls: OwnershipControlsUnionTypeDef
    ContentMD5: NotRequired[str]
    ExpectedBucketOwner: NotRequired[str]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]

class GetBucketLoggingOutputTypeDef(TypedDict):
    LoggingEnabled: LoggingEnabledOutputTypeDef
    ResponseMetadata: ResponseMetadataTypeDef

class LoggingEnabledTypeDef(TypedDict):
    TargetBucket: str
    TargetPrefix: str
    TargetGrants: NotRequired[Sequence[TargetGrantTypeDef]]
    TargetObjectKeyFormat: NotRequired[TargetObjectKeyFormatUnionTypeDef]

class PutBucketWebsiteRequestBucketWebsitePutTypeDef(TypedDict):
    WebsiteConfiguration: WebsiteConfigurationTypeDef
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ExpectedBucketOwner: NotRequired[str]

class PutBucketWebsiteRequestTypeDef(TypedDict):
    Bucket: str
    WebsiteConfiguration: WebsiteConfigurationTypeDef
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ExpectedBucketOwner: NotRequired[str]

class GetBucketEncryptionOutputTypeDef(TypedDict):
    ServerSideEncryptionConfiguration: ServerSideEncryptionConfigurationOutputTypeDef
    ResponseMetadata: ResponseMetadataTypeDef

ServerSideEncryptionConfigurationUnionTypeDef = Union[
    ServerSideEncryptionConfigurationTypeDef, ServerSideEncryptionConfigurationOutputTypeDef
]

class SelectObjectContentOutputTypeDef(TypedDict):
    Payload: EventStream[SelectObjectContentEventStreamTypeDef]
    ResponseMetadata: ResponseMetadataTypeDef

class PutBucketNotificationRequestTypeDef(TypedDict):
    Bucket: str
    NotificationConfiguration: NotificationConfigurationDeprecatedTypeDef
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ExpectedBucketOwner: NotRequired[str]

RuleUnionTypeDef = Union[RuleTypeDef, RuleOutputTypeDef]

class GetBucketIntelligentTieringConfigurationOutputTypeDef(TypedDict):
    IntelligentTieringConfiguration: IntelligentTieringConfigurationOutputTypeDef
    ResponseMetadata: ResponseMetadataTypeDef

class ListBucketIntelligentTieringConfigurationsOutputTypeDef(TypedDict):
    IsTruncated: bool
    ContinuationToken: str
    NextContinuationToken: str
    IntelligentTieringConfigurationList: List[IntelligentTieringConfigurationOutputTypeDef]
    ResponseMetadata: ResponseMetadataTypeDef

IntelligentTieringConfigurationUnionTypeDef = Union[
    IntelligentTieringConfigurationTypeDef, IntelligentTieringConfigurationOutputTypeDef
]

class GetBucketLifecycleConfigurationOutputTypeDef(TypedDict):
    Rules: List[LifecycleRuleOutputTypeDef]
    TransitionDefaultMinimumObjectSize: TransitionDefaultMinimumObjectSizeType
    ResponseMetadata: ResponseMetadataTypeDef

LifecycleRuleFilterUnionTypeDef = Union[
    LifecycleRuleFilterTypeDef, LifecycleRuleFilterOutputTypeDef
]

class GetBucketMetricsConfigurationOutputTypeDef(TypedDict):
    MetricsConfiguration: MetricsConfigurationOutputTypeDef
    ResponseMetadata: ResponseMetadataTypeDef

class ListBucketMetricsConfigurationsOutputTypeDef(TypedDict):
    IsTruncated: bool
    ContinuationToken: str
    NextContinuationToken: str
    MetricsConfigurationList: List[MetricsConfigurationOutputTypeDef]
    ResponseMetadata: ResponseMetadataTypeDef

MetricsConfigurationUnionTypeDef = Union[
    MetricsConfigurationTypeDef, MetricsConfigurationOutputTypeDef
]

class AnalyticsConfigurationOutputTypeDef(TypedDict):
    Id: str
    StorageClassAnalysis: StorageClassAnalysisTypeDef
    Filter: NotRequired[AnalyticsFilterOutputTypeDef]

class AnalyticsConfigurationTypeDef(TypedDict):
    Id: str
    StorageClassAnalysis: StorageClassAnalysisTypeDef
    Filter: NotRequired[AnalyticsFilterTypeDef]

class NotificationConfigurationResponseTypeDef(TypedDict):
    TopicConfigurations: List[TopicConfigurationOutputTypeDef]
    QueueConfigurations: List[QueueConfigurationOutputTypeDef]
    LambdaFunctionConfigurations: List[LambdaFunctionConfigurationOutputTypeDef]
    EventBridgeConfiguration: Dict[str, Any]
    ResponseMetadata: ResponseMetadataTypeDef

NotificationConfigurationFilterUnionTypeDef = Union[
    NotificationConfigurationFilterTypeDef, NotificationConfigurationFilterOutputTypeDef
]
RestoreRequestTypeDef = TypedDict(
    "RestoreRequestTypeDef",
    {
        "Days": NotRequired[int],
        "GlacierJobParameters": NotRequired[GlacierJobParametersTypeDef],
        "Type": NotRequired[Literal["SELECT"]],
        "Tier": NotRequired[TierType],
        "Description": NotRequired[str],
        "SelectParameters": NotRequired[SelectParametersTypeDef],
        "OutputLocation": NotRequired[OutputLocationTypeDef],
    },
)

class InventoryConfigurationOutputTypeDef(TypedDict):
    Destination: InventoryDestinationOutputTypeDef
    IsEnabled: bool
    Id: str
    IncludedObjectVersions: InventoryIncludedObjectVersionsType
    Schedule: InventoryScheduleTypeDef
    Filter: NotRequired[InventoryFilterTypeDef]
    OptionalFields: NotRequired[List[InventoryOptionalFieldType]]

class InventoryConfigurationTypeDef(TypedDict):
    Destination: InventoryDestinationTypeDef
    IsEnabled: bool
    Id: str
    IncludedObjectVersions: InventoryIncludedObjectVersionsType
    Schedule: InventoryScheduleTypeDef
    Filter: NotRequired[InventoryFilterTypeDef]
    OptionalFields: NotRequired[Sequence[InventoryOptionalFieldType]]

class ReplicationConfigurationOutputTypeDef(TypedDict):
    Role: str
    Rules: List[ReplicationRuleOutputTypeDef]

class ReplicationConfigurationTypeDef(TypedDict):
    Role: str
    Rules: Sequence[ReplicationRuleTypeDef]

LoggingEnabledUnionTypeDef = Union[LoggingEnabledTypeDef, LoggingEnabledOutputTypeDef]

class PutBucketEncryptionRequestTypeDef(TypedDict):
    Bucket: str
    ServerSideEncryptionConfiguration: ServerSideEncryptionConfigurationUnionTypeDef
    ContentMD5: NotRequired[str]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ExpectedBucketOwner: NotRequired[str]

class LifecycleConfigurationTypeDef(TypedDict):
    Rules: Sequence[RuleUnionTypeDef]

class PutBucketIntelligentTieringConfigurationRequestTypeDef(TypedDict):
    Bucket: str
    Id: str
    IntelligentTieringConfiguration: IntelligentTieringConfigurationUnionTypeDef
    ExpectedBucketOwner: NotRequired[str]

class LifecycleRuleTypeDef(TypedDict):
    Status: ExpirationStatusType
    Expiration: NotRequired[LifecycleExpirationUnionTypeDef]
    ID: NotRequired[str]
    Prefix: NotRequired[str]
    Filter: NotRequired[LifecycleRuleFilterUnionTypeDef]
    Transitions: NotRequired[Sequence[TransitionUnionTypeDef]]
    NoncurrentVersionTransitions: NotRequired[Sequence[NoncurrentVersionTransitionTypeDef]]
    NoncurrentVersionExpiration: NotRequired[NoncurrentVersionExpirationTypeDef]
    AbortIncompleteMultipartUpload: NotRequired[AbortIncompleteMultipartUploadTypeDef]

class PutBucketMetricsConfigurationRequestTypeDef(TypedDict):
    Bucket: str
    Id: str
    MetricsConfiguration: MetricsConfigurationUnionTypeDef
    ExpectedBucketOwner: NotRequired[str]

class GetBucketAnalyticsConfigurationOutputTypeDef(TypedDict):
    AnalyticsConfiguration: AnalyticsConfigurationOutputTypeDef
    ResponseMetadata: ResponseMetadataTypeDef

class ListBucketAnalyticsConfigurationsOutputTypeDef(TypedDict):
    IsTruncated: bool
    ContinuationToken: str
    NextContinuationToken: str
    AnalyticsConfigurationList: List[AnalyticsConfigurationOutputTypeDef]
    ResponseMetadata: ResponseMetadataTypeDef

AnalyticsConfigurationUnionTypeDef = Union[
    AnalyticsConfigurationTypeDef, AnalyticsConfigurationOutputTypeDef
]

class LambdaFunctionConfigurationTypeDef(TypedDict):
    LambdaFunctionArn: str
    Events: Sequence[EventType]
    Id: NotRequired[str]
    Filter: NotRequired[NotificationConfigurationFilterUnionTypeDef]

class QueueConfigurationTypeDef(TypedDict):
    QueueArn: str
    Events: Sequence[EventType]
    Id: NotRequired[str]
    Filter: NotRequired[NotificationConfigurationFilterUnionTypeDef]

class TopicConfigurationTypeDef(TypedDict):
    TopicArn: str
    Events: Sequence[EventType]
    Id: NotRequired[str]
    Filter: NotRequired[NotificationConfigurationFilterUnionTypeDef]

class RestoreObjectRequestObjectRestoreObjectTypeDef(TypedDict):
    VersionId: NotRequired[str]
    RestoreRequest: NotRequired[RestoreRequestTypeDef]
    RequestPayer: NotRequired[Literal["requester"]]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ExpectedBucketOwner: NotRequired[str]

class RestoreObjectRequestObjectSummaryRestoreObjectTypeDef(TypedDict):
    VersionId: NotRequired[str]
    RestoreRequest: NotRequired[RestoreRequestTypeDef]
    RequestPayer: NotRequired[Literal["requester"]]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ExpectedBucketOwner: NotRequired[str]

class RestoreObjectRequestTypeDef(TypedDict):
    Bucket: str
    Key: str
    VersionId: NotRequired[str]
    RestoreRequest: NotRequired[RestoreRequestTypeDef]
    RequestPayer: NotRequired[Literal["requester"]]
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ExpectedBucketOwner: NotRequired[str]

class GetBucketInventoryConfigurationOutputTypeDef(TypedDict):
    InventoryConfiguration: InventoryConfigurationOutputTypeDef
    ResponseMetadata: ResponseMetadataTypeDef

class ListBucketInventoryConfigurationsOutputTypeDef(TypedDict):
    ContinuationToken: str
    InventoryConfigurationList: List[InventoryConfigurationOutputTypeDef]
    IsTruncated: bool
    NextContinuationToken: str
    ResponseMetadata: ResponseMetadataTypeDef

InventoryConfigurationUnionTypeDef = Union[
    InventoryConfigurationTypeDef, InventoryConfigurationOutputTypeDef
]

class GetBucketReplicationOutputTypeDef(TypedDict):
    ReplicationConfiguration: ReplicationConfigurationOutputTypeDef
    ResponseMetadata: ResponseMetadataTypeDef

ReplicationConfigurationUnionTypeDef = Union[
    ReplicationConfigurationTypeDef, ReplicationConfigurationOutputTypeDef
]

class BucketLoggingStatusTypeDef(TypedDict):
    LoggingEnabled: NotRequired[LoggingEnabledUnionTypeDef]

class PutBucketLifecycleRequestBucketLifecyclePutTypeDef(TypedDict):
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    LifecycleConfiguration: NotRequired[LifecycleConfigurationTypeDef]
    ExpectedBucketOwner: NotRequired[str]

class PutBucketLifecycleRequestTypeDef(TypedDict):
    Bucket: str
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    LifecycleConfiguration: NotRequired[LifecycleConfigurationTypeDef]
    ExpectedBucketOwner: NotRequired[str]

LifecycleRuleUnionTypeDef = Union[LifecycleRuleTypeDef, LifecycleRuleOutputTypeDef]

class PutBucketAnalyticsConfigurationRequestTypeDef(TypedDict):
    Bucket: str
    Id: str
    AnalyticsConfiguration: AnalyticsConfigurationUnionTypeDef
    ExpectedBucketOwner: NotRequired[str]

LambdaFunctionConfigurationUnionTypeDef = Union[
    LambdaFunctionConfigurationTypeDef, LambdaFunctionConfigurationOutputTypeDef
]
QueueConfigurationUnionTypeDef = Union[QueueConfigurationTypeDef, QueueConfigurationOutputTypeDef]
TopicConfigurationUnionTypeDef = Union[TopicConfigurationTypeDef, TopicConfigurationOutputTypeDef]

class PutBucketInventoryConfigurationRequestTypeDef(TypedDict):
    Bucket: str
    Id: str
    InventoryConfiguration: InventoryConfigurationUnionTypeDef
    ExpectedBucketOwner: NotRequired[str]

class PutBucketReplicationRequestTypeDef(TypedDict):
    Bucket: str
    ReplicationConfiguration: ReplicationConfigurationUnionTypeDef
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    Token: NotRequired[str]
    ExpectedBucketOwner: NotRequired[str]

class PutBucketLoggingRequestBucketLoggingPutTypeDef(TypedDict):
    BucketLoggingStatus: BucketLoggingStatusTypeDef
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ExpectedBucketOwner: NotRequired[str]

class PutBucketLoggingRequestTypeDef(TypedDict):
    Bucket: str
    BucketLoggingStatus: BucketLoggingStatusTypeDef
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    ExpectedBucketOwner: NotRequired[str]

class BucketLifecycleConfigurationTypeDef(TypedDict):
    Rules: Sequence[LifecycleRuleUnionTypeDef]

class NotificationConfigurationTypeDef(TypedDict):
    TopicConfigurations: NotRequired[Sequence[TopicConfigurationUnionTypeDef]]
    QueueConfigurations: NotRequired[Sequence[QueueConfigurationUnionTypeDef]]
    LambdaFunctionConfigurations: NotRequired[Sequence[LambdaFunctionConfigurationUnionTypeDef]]
    EventBridgeConfiguration: NotRequired[Mapping[str, Any]]

class PutBucketLifecycleConfigurationRequestBucketLifecycleConfigurationPutTypeDef(TypedDict):
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    LifecycleConfiguration: NotRequired[BucketLifecycleConfigurationTypeDef]
    ExpectedBucketOwner: NotRequired[str]
    TransitionDefaultMinimumObjectSize: NotRequired[TransitionDefaultMinimumObjectSizeType]

class PutBucketLifecycleConfigurationRequestTypeDef(TypedDict):
    Bucket: str
    ChecksumAlgorithm: NotRequired[ChecksumAlgorithmType]
    LifecycleConfiguration: NotRequired[BucketLifecycleConfigurationTypeDef]
    ExpectedBucketOwner: NotRequired[str]
    TransitionDefaultMinimumObjectSize: NotRequired[TransitionDefaultMinimumObjectSizeType]

class PutBucketNotificationConfigurationRequestBucketNotificationPutTypeDef(TypedDict):
    NotificationConfiguration: NotificationConfigurationTypeDef
    ExpectedBucketOwner: NotRequired[str]
    SkipDestinationValidation: NotRequired[bool]

class PutBucketNotificationConfigurationRequestTypeDef(TypedDict):
    Bucket: str
    NotificationConfiguration: NotificationConfigurationTypeDef
    ExpectedBucketOwner: NotRequired[str]
    SkipDestinationValidation: NotRequired[bool]
