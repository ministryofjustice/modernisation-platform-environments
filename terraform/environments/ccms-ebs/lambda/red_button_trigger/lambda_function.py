"""
AWS Lambda Red Button - Emergency Security Group Isolation
Stage 4: JSON Serialization & S3 Storage
"""

import json
import logging
import os
import hashlib
from typing import Dict, Any, Optional, List, Set, Tuple
from datetime import datetime, timezone
from dataclasses import dataclass

import boto3
from botocore.exceptions import ClientError, NoCredentialsError


@dataclass
class SecurityGroupRule:
    """Represents a single Security Group rule."""
    ip_protocol: str
    from_port: Optional[int] = None
    to_port: Optional[int] = None
    cidr_blocks: Optional[List[str]] = None
    ipv6_cidr_blocks: Optional[List[str]] = None
    prefix_list_ids: Optional[List[str]] = None
    referenced_group_info: Optional[Dict[str, str]] = None
    description: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        """Convert rule to dictionary for JSON serialization."""
        rule_dict: Dict[str, Any] = {'ip_protocol': self.ip_protocol}
        
        if self.from_port is not None:
            rule_dict['from_port'] = self.from_port
        if self.to_port is not None:
            rule_dict['to_port'] = self.to_port
        if self.cidr_blocks:
            rule_dict['cidr_blocks'] = self.cidr_blocks
        if self.ipv6_cidr_blocks:
            rule_dict['ipv6_cidr_blocks'] = self.ipv6_cidr_blocks
        if self.prefix_list_ids:
            rule_dict['prefix_list_ids'] = self.prefix_list_ids
        if self.referenced_group_info:
            rule_dict['referenced_group_info'] = self.referenced_group_info
        if self.description:
            rule_dict['description'] = self.description
            
        return rule_dict


@dataclass
class SecurityGroupData:
    """Complete Security Group information for backup and restoration."""
    metadata: Dict[str, Any]
    ingress_rules: List[SecurityGroupRule]
    egress_rules: List[SecurityGroupRule]
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization."""
        return {
            'metadata': self.metadata,
            'ingress_rules': [rule.to_dict() for rule in self.ingress_rules],
            'egress_rules': [rule.to_dict() for rule in self.egress_rules]
        }


class RedButtonLambda:
    """AWS Lambda Red Button for emergency EC2 security group isolation."""
    
    def __init__(self):
        """Initialize the Red Button Lambda with AWS clients and configuration."""
        self.logger = self._setup_logging()
        self.config = self._load_configuration()
        self.aws_clients = self._initialize_aws_clients()
        # Set execution timestamp for consistent directory naming
        self.execution_timestamp = datetime.now(timezone.utc)
        
    def _setup_logging(self) -> logging.Logger:
        """Configure logging based on DEBUG environment variable."""
        logger = logging.getLogger(__name__)
        
        # Clear any existing handlers
        for handler in logger.handlers[:]:
            logger.removeHandler(handler)
            
        # Set logging level
        debug_mode = os.getenv('DEBUG', 'false').lower() == 'true'
        level = logging.DEBUG if debug_mode else logging.INFO
        logger.setLevel(level)
        
        # Create handler with proper formatting
        handler = logging.StreamHandler()
        formatter = logging.Formatter(
            '[%(asctime)s] %(levelname)s - %(name)s - %(message)s'
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        
        return logger
    
    def _load_configuration(self) -> Dict[str, Any]:
        """Load and validate Lambda configuration from environment variables."""
        config = {
            's3_bucket': os.getenv('S3_BUCKET_REDBUTTON'),
            'boom_mode': os.getenv('BOOM', 'false').lower() == 'true',
            'debug_mode': os.getenv('DEBUG', 'false').lower() == 'true',
            'aws_region': os.getenv('AWS_DEFAULT_REGION', 'us-east-1')
        }
        
        # Validate required configuration
        if not config['s3_bucket']:
            raise ValueError("S3_BUCKET_REDBUTTON environment variable is required")
        
        self.logger.info(f"Configuration loaded: {config}")
        return config
    
    def _initialize_aws_clients(self) -> Dict[str, Any]:
        """Initialize AWS service clients with proper error handling."""
        clients: Dict[str, Any] = {}
        
        try:
            # EC2 client for Security Group operations
            clients['ec2'] = boto3.client('ec2', region_name=self.config['aws_region'])
            
            # S3 client for backup storage
            clients['s3'] = boto3.client('s3', region_name=self.config['aws_region'])
            
            self.logger.info("AWS clients initialized successfully")
            
        except NoCredentialsError:
            self.logger.error("AWS credentials not found")
            raise
        except Exception as e:
            self.logger.error(f"Failed to initialize AWS clients: {str(e)}")
            raise
            
        return clients
    
    def test_aws_connectivity(self) -> Dict[str, Any]:
        """Test connectivity to AWS services and validate permissions."""
        connectivity_results = {
            'ec2': {'status': 'unknown', 'message': ''},
            's3': {'status': 'unknown', 'message': ''},
            'overall': {'status': 'unknown', 'message': ''}
        }
        
        # Test EC2 connectivity
        try:
            response = self.aws_clients['ec2'].describe_regions(RegionNames=[self.config['aws_region']])
            if response['Regions']:
                connectivity_results['ec2'] = {
                    'status': 'success',
                    'message': f"Connected to EC2 in region {self.config['aws_region']}"
                }
            else:
                connectivity_results['ec2'] = {
                    'status': 'error',
                    'message': f"Region {self.config['aws_region']} not available"
                }
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', 'Unknown')
            connectivity_results['ec2'] = {
                'status': 'error',
                'message': f"EC2 connection failed: {error_code}"
            }
        except Exception as e:
            connectivity_results['ec2'] = {
                'status': 'error',
                'message': f"EC2 connection failed: {str(e)}"
            }
        
        # Test S3 connectivity
        try:
            self.aws_clients['s3'].head_bucket(Bucket=self.config['s3_bucket'])
            connectivity_results['s3'] = {
                'status': 'success',
                'message': f"S3 bucket {self.config['s3_bucket']} accessible"
            }
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', 'Unknown')
            if error_code == '404':
                connectivity_results['s3'] = {
                    'status': 'error',
                    'message': f"S3 bucket {self.config['s3_bucket']} not found"
                }
            elif error_code == '403':
                connectivity_results['s3'] = {
                    'status': 'error',
                    'message': f"Access denied to S3 bucket {self.config['s3_bucket']}"
                }
            else:
                connectivity_results['s3'] = {
                    'status': 'error',
                    'message': f"S3 connection failed: {error_code}"
                }
        except Exception as e:
            connectivity_results['s3'] = {
                'status': 'error',
                'message': f"S3 connection failed: {str(e)}"
            }
        
        # Determine overall status
        ec2_ok = connectivity_results['ec2']['status'] == 'success'
        s3_ok = connectivity_results['s3']['status'] == 'success'
        
        if ec2_ok and s3_ok:
            connectivity_results['overall'] = {
                'status': 'success',
                'message': 'All AWS services accessible'
            }
        elif ec2_ok or s3_ok:
            connectivity_results['overall'] = {
                'status': 'partial',
                'message': 'Some AWS services accessible'
            }
        else:
            connectivity_results['overall'] = {
                'status': 'error',
                'message': 'No AWS services accessible'
            }
        
        self.logger.info(f"AWS connectivity test results: {connectivity_results}")
        return connectivity_results
    
    def get_aws_account_info(self) -> Dict[str, Any]:
        """Get basic AWS account information for verification."""
        try:
            sts_client = boto3.client('sts', region_name=self.config['aws_region'])
            identity = sts_client.get_caller_identity()
            
            account_info = {
                'account_id': identity.get('Account'),
                'user_arn': identity.get('Arn'),
                'user_id': identity.get('UserId'),
                'region': self.config['aws_region']
            }
            
            self.logger.info(f"AWS account info: {account_info}")
            return account_info
            
        except Exception as e:
            self.logger.error(f"Failed to get AWS account info: {str(e)}")
            return {'error': str(e)}
    
    def discover_ec2_security_groups(self) -> Set[str]:
        """Discover all Security Groups attached to EC2 instances."""
        try:
            security_group_ids: Set[str] = set()
            
            # Get all EC2 instances
            response = self.aws_clients['ec2'].describe_instances()
            
            instance_count = 0
            for reservation in response['Reservations']:
                for instance in reservation['Instances']:
                    instance_count += 1
                    instance_id = instance['InstanceId']
                    state = instance['State']['Name']
                    
                    self.logger.debug(f"Processing instance {instance_id} (state: {state})")
                    
                    # Extract Security Groups from all network interfaces
                    for interface in instance.get('NetworkInterfaces', []):
                        for sg in interface.get('Groups', []):
                            sg_id = sg['GroupId']
                            security_group_ids.add(sg_id)
                            self.logger.debug(f"Found Security Group {sg_id} on instance {instance_id}")
            
            self.logger.info(f"Discovered {len(security_group_ids)} unique Security Groups from {instance_count} instances")
            return security_group_ids
            
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', 'Unknown')
            self.logger.error(f"Failed to discover EC2 Security Groups: {error_code}")
            raise
        except Exception as e:
            self.logger.error(f"Unexpected error during SG discovery: {str(e)}")
            raise
    
    def _parse_security_group_rule(self, rule_data: Dict[str, Any]) -> SecurityGroupRule:
        """Parse AWS Security Group rule data into SecurityGroupRule object."""
        # Extract basic rule information
        ip_protocol = rule_data.get('IpProtocol', '')
        from_port = rule_data.get('FromPort')
        to_port = rule_data.get('ToPort')
        description = rule_data.get('Description')
        
        # Extract IP ranges
        cidr_blocks = [ip_range['CidrIp'] for ip_range in rule_data.get('IpRanges', [])]
        ipv6_cidr_blocks = [ip_range['CidrIpv6'] for ip_range in rule_data.get('Ipv6Ranges', [])]
        prefix_list_ids = [pl['PrefixListId'] for pl in rule_data.get('PrefixListIds', [])]
        
        # Extract referenced Security Group information
        referenced_group_info = None
        user_id_group_pairs = rule_data.get('UserIdGroupPairs', [])
        if user_id_group_pairs:
            # For simplicity, we'll take the first referenced group
            # In practice, there could be multiple
            ref_group = user_id_group_pairs[0]
            referenced_group_info = {
                'group_id': ref_group.get('GroupId', ''),
                'user_id': ref_group.get('UserId', ''),
                'vpc_id': ref_group.get('VpcId', ''),
                'description': ref_group.get('Description', '')
            }
        
        return SecurityGroupRule(
            ip_protocol=ip_protocol,
            from_port=from_port,
            to_port=to_port,
            cidr_blocks=cidr_blocks if cidr_blocks else None,
            ipv6_cidr_blocks=ipv6_cidr_blocks if ipv6_cidr_blocks else None,
            prefix_list_ids=prefix_list_ids if prefix_list_ids else None,
            referenced_group_info=referenced_group_info,
            description=description
        )
    
    def extract_security_group_data(self, security_group_ids: Set[str]) -> Dict[str, SecurityGroupData]:
        """Extract detailed information for all Security Groups."""
        try:
            sg_data: Dict[str, SecurityGroupData] = {}
            
            if not security_group_ids:
                self.logger.warning("No Security Group IDs provided for extraction")
                return sg_data
            
            # Convert set to list for API call
            sg_id_list = list(security_group_ids)
            self.logger.info(f"Extracting data for {len(sg_id_list)} Security Groups")
            
            # Get detailed Security Group information
            response = self.aws_clients['ec2'].describe_security_groups(GroupIds=sg_id_list)
            
            for sg in response['SecurityGroups']:
                sg_id = sg['GroupId']
                
                # Extract metadata
                metadata = {
                    'group_id': sg_id,
                    'group_name': sg.get('GroupName', ''),
                    'description': sg.get('Description', ''),
                    'vpc_id': sg.get('VpcId', ''),
                    'owner_id': sg.get('OwnerId', ''),
                    'tags': {tag['Key']: tag['Value'] for tag in sg.get('Tags', [])}
                }
                
                # Parse ingress rules
                ingress_rules = []
                for rule_data in sg.get('IpPermissions', []):
                    rule = self._parse_security_group_rule(rule_data)
                    ingress_rules.append(rule)
                
                # Parse egress rules
                egress_rules = []
                for rule_data in sg.get('IpPermissionsEgress', []):
                    rule = self._parse_security_group_rule(rule_data)
                    egress_rules.append(rule)
                
                # Create SecurityGroupData object
                sg_data[sg_id] = SecurityGroupData(
                    metadata=metadata,
                    ingress_rules=ingress_rules,
                    egress_rules=egress_rules
                )
                
                self.logger.debug(f"Extracted SG {sg_id}: {len(ingress_rules)} ingress, {len(egress_rules)} egress rules")
            
            self.logger.info(f"Successfully extracted data for {len(sg_data)} Security Groups")
            return sg_data
            
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', 'Unknown')
            self.logger.error(f"Failed to extract Security Group data: {error_code}")
            raise
        except Exception as e:
            self.logger.error(f"Unexpected error during SG data extraction: {str(e)}")
            raise
    
    def discover_and_extract_security_groups(self) -> Dict[str, SecurityGroupData]:
        """Main method to discover and extract all Security Group data."""
        try:
            self.logger.info("Starting Security Group discovery and extraction")
            
            # Step 1: Discover Security Groups from EC2 instances
            security_group_ids = self.discover_ec2_security_groups()
            
            if not security_group_ids:
                self.logger.warning("No Security Groups found attached to EC2 instances")
                return {}
            
            # Step 2: Extract detailed Security Group data
            sg_data = self.extract_security_group_data(security_group_ids)
            
            self.logger.info(f"Discovery and extraction completed: {len(sg_data)} Security Groups processed")
            return sg_data
            
        except Exception as e:
            self.logger.error(f"Failed to discover and extract Security Groups: {str(e)}")
            raise
    
    def _generate_sg_filename(self, sg_data: SecurityGroupData) -> str:
        """Generate filename for Security Group backup using {sg_id}-{sg_name}.json format."""
        sg_id = sg_data.metadata['group_id']
        sg_name = sg_data.metadata.get('group_name', 'unknown')
        
        # Get name from tags if available, fallback to group name
        tags = sg_data.metadata.get('tags', {})
        name_tag = tags.get('Name', tags.get('name', sg_name))
        
        # Sanitize filename by removing invalid characters
        safe_name = ''.join(c for c in name_tag if c.isalnum() or c in '-_').rstrip()
        if not safe_name:
            safe_name = 'unnamed'
        
        return f"{sg_id}-{safe_name}.json"
    
    def _calculate_content_hash(self, content: str) -> str:
        """Calculate SHA256 hash of content for integrity verification."""
        return hashlib.sha256(content.encode('utf-8')).hexdigest()
    
    def backup_security_group_to_s3(self, sg_id: str, sg_data: SecurityGroupData) -> Dict[str, Any]:
        """Backup a single Security Group to S3 with integrity verification."""
        try:
            # Generate filename and prepare content
            filename = self._generate_sg_filename(sg_data)
            timestamp = self.execution_timestamp.isoformat()
            
            # Prepare backup data with metadata
            backup_content = {
                'backup_metadata': {
                    'timestamp': timestamp,
                    'lambda_version': 'stage4',
                    'security_group_id': sg_id
                },
                'security_group_data': sg_data.to_dict()
            }
            
            # Serialize to JSON with proper formatting
            json_content = json.dumps(backup_content, indent=2, sort_keys=True)
            content_hash = self._calculate_content_hash(json_content)
            
            # Generate timestamped directory path
            timestamp_dir = self.execution_timestamp.strftime("%Y%m%d-%H%M%S")
            s3_key = f"{timestamp_dir}-security-groups/{filename}"
            
            self.aws_clients['s3'].put_object(
                Bucket=self.config['s3_bucket'],
                Key=s3_key,
                Body=json_content.encode('utf-8'),
                ContentType='application/json',
                Metadata={
                    'security-group-id': sg_id,
                    'backup-timestamp': timestamp,
                    'content-hash': content_hash,
                    'lambda-stage': 'stage4'
                }
            )
            
            self.logger.info(f"Successfully backed up Security Group {sg_id} to S3: {s3_key}")
            
            # Return backup result
            return {
                'sg_id': sg_id,
                'filename': filename,
                's3_key': s3_key,
                'content_hash': content_hash,
                'size_bytes': len(json_content.encode('utf-8')),
                'timestamp': timestamp,
                'status': 'success'
            }
            
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', 'Unknown')
            error_msg = f"S3 upload failed for {sg_id}: {error_code}"
            self.logger.error(error_msg)
            return {
                'sg_id': sg_id,
                'status': 'error',
                'error': error_msg,
                'timestamp': datetime.now(timezone.utc).isoformat()
            }
        except Exception as e:
            error_msg = f"Backup failed for {sg_id}: {str(e)}"
            self.logger.error(error_msg)
            return {
                'sg_id': sg_id,
                'status': 'error',
                'error': error_msg,
                'timestamp': datetime.now(timezone.utc).isoformat()
            }
    
    def verify_s3_backup(self, backup_result: Dict[str, Any]) -> Dict[str, Any]:
        """Verify S3 backup integrity by downloading and comparing hashes."""
        if backup_result['status'] != 'success':
            return {'status': 'skipped', 'reason': 'backup_failed'}
        
        try:
            sg_id = backup_result['sg_id']
            s3_key = backup_result['s3_key']
            original_hash = backup_result['content_hash']
            
            # Download the object from S3
            response = self.aws_clients['s3'].get_object(
                Bucket=self.config['s3_bucket'],
                Key=s3_key
            )
            
            # Read content and calculate hash
            downloaded_content = response['Body'].read().decode('utf-8')
            downloaded_hash = self._calculate_content_hash(downloaded_content)
            
            # Compare hashes
            integrity_valid = original_hash == downloaded_hash
            
            verification_result = {
                'sg_id': sg_id,
                's3_key': s3_key,
                'integrity_valid': integrity_valid,
                'original_hash': original_hash,
                'downloaded_hash': downloaded_hash,
                'status': 'success' if integrity_valid else 'hash_mismatch'
            }
            
            if integrity_valid:
                self.logger.debug(f"Backup verification successful for {sg_id}")
            else:
                self.logger.error(f"Backup verification failed for {sg_id}: hash mismatch")
            
            return verification_result
            
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', 'Unknown')
            error_msg = f"S3 verification failed: {error_code}"
            self.logger.error(error_msg)
            return {
                'sg_id': backup_result.get('sg_id', 'unknown'),
                'status': 'error',
                'error': error_msg
            }
        except Exception as e:
            error_msg = f"Verification failed: {str(e)}"
            self.logger.error(error_msg)
            return {
                'sg_id': backup_result.get('sg_id', 'unknown'),
                'status': 'error',
                'error': error_msg
            }
    
    def backup_all_security_groups_to_s3(self, security_groups: Dict[str, SecurityGroupData]) -> Dict[str, Any]:
        """Backup all Security Groups to S3 with verification."""
        backup_results = []
        verification_results = []
        
        if not security_groups:
            self.logger.warning("No Security Groups to backup")
            return {
                'total_groups': 0,
                'successful_backups': 0,
                'failed_backups': 0,
                'successful_verifications': 0,
                'failed_verifications': 0,
                'backup_details': [],
                'verification_details': []
            }
        
        self.logger.info(f"Starting backup of {len(security_groups)} Security Groups to S3")
        
        # Backup each Security Group
        for sg_id, sg_data in security_groups.items():
            backup_result = self.backup_security_group_to_s3(sg_id, sg_data)
            backup_results.append(backup_result)
            
            # Verify backup if successful
            if backup_result['status'] == 'success':
                verification_result = self.verify_s3_backup(backup_result)
                verification_results.append(verification_result)
        
        # Calculate summary statistics
        successful_backups = sum(1 for r in backup_results if r['status'] == 'success')
        failed_backups = len(backup_results) - successful_backups
        successful_verifications = sum(1 for r in verification_results if r['status'] == 'success')
        failed_verifications = len(verification_results) - successful_verifications
        
        summary = {
            'total_groups': len(security_groups),
            'successful_backups': successful_backups,
            'failed_backups': failed_backups,
            'successful_verifications': successful_verifications,
            'failed_verifications': failed_verifications,
            'backup_details': backup_results,
            'verification_details': verification_results
        }
        
        self.logger.info(f"Backup completed: {successful_backups}/{len(security_groups)} successful, "
                        f"{successful_verifications}/{len(verification_results)} verified")
        
        return summary
    
    def _determine_overall_status(self, connectivity: Dict[str, Any], sg_summary: Dict[str, Any], backup_summary: Dict[str, Any]) -> str:
        """Determine overall status based on connectivity, discovery, and backup results."""
        # Check for critical errors
        if connectivity['overall']['status'] == 'error':
            return 'error'
        
        if sg_summary.get('error'):
            return 'error'
        
        if backup_summary.get('error'):
            return 'error'
        
        # Check for partial success
        if connectivity['overall']['status'] == 'partial':
            return 'warning'
        
        # Check backup success rates
        total_groups = backup_summary.get('total_groups', 0)
        if total_groups > 0:
            successful_backups = backup_summary.get('successful_backups', 0)
            successful_verifications = backup_summary.get('successful_verifications', 0)
            
            # All backups successful and verified
            if successful_backups == total_groups and successful_verifications == successful_backups:
                return 'success'
            # Some backups successful
            elif successful_backups > 0:
                return 'warning'
            else:
                return 'error'
        
        # No groups to backup but everything else successful
        return 'success'
    
    def process_request(self, event: Dict[str, Any]) -> Dict[str, Any]:
        """Main processing logic for the Lambda function."""
        try:
            self.logger.info(f"Processing request with event: {event}")
            
            # Get AWS account information
            account_info = self.get_aws_account_info()
            
            # Test AWS connectivity
            connectivity = self.test_aws_connectivity()
            
            # Stage 4: Discover, extract, and backup Security Groups
            security_groups = {}
            sg_summary: Dict[str, Any] = {'discovered': 0, 'extracted': 0, 'error': None}
            backup_summary: Dict[str, Any] = {}
            
            try:
                security_groups = self.discover_and_extract_security_groups()
                sg_summary['discovered'] = len(security_groups)
                sg_summary['extracted'] = len(security_groups)
                
                # Stage 4: Backup to S3
                if security_groups:
                    backup_summary = self.backup_all_security_groups_to_s3(security_groups)
                else:
                    backup_summary = {
                        'total_groups': 0,
                        'successful_backups': 0,
                        'failed_backups': 0,
                        'successful_verifications': 0,
                        'failed_verifications': 0,
                        'backup_details': [],
                        'verification_details': []
                    }
                
            except Exception as e:
                sg_summary['error'] = str(e)
                self.logger.error(f"Security Group discovery failed: {str(e)}")
                backup_summary = {'error': str(e)}
            
            # Prepare response
            response_data = {
                'message': 'Red Button Lambda - Stage 4 Implementation',
                'stage': 4,
                'timestamp': datetime.now(timezone.utc).isoformat(),
                'configuration': {
                    's3_bucket': self.config['s3_bucket'],
                    'boom_mode': self.config['boom_mode'],
                    'debug_mode': self.config['debug_mode'],
                    'aws_region': self.config['aws_region']
                },
                'aws_account': account_info,
                'connectivity': connectivity,
                'security_groups': {
                    'summary': sg_summary,
                    'details': {sg_id: sg_data.to_dict() for sg_id, sg_data in security_groups.items()}
                },
                'backup_results': backup_summary,
                'status': self._determine_overall_status(connectivity, sg_summary, backup_summary)
            }
            
            overall_status = response_data['status']
            if overall_status == 'success':
                status_code = 200
            elif overall_status == 'warning':
                status_code = 206  # Partial Content
            else:
                status_code = 500
            
            self.logger.info("Request processed successfully")
            return {
                'statusCode': status_code,
                'body': json.dumps(response_data, indent=2)
            }
            
        except Exception as e:
            self.logger.error(f"Error processing request: {str(e)}", exc_info=True)
            return {
                'statusCode': 500,
                'body': json.dumps({
                    'message': 'Internal server error',
                    'error': str(e),
                    'stage': 4,
                    'timestamp': datetime.now(timezone.utc).isoformat(),
                    'status': 'error'
                }, indent=2)
            }


# Lambda function entry point
def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    AWS Lambda handler function.
    
    Args:
        event: Lambda event data
        context: Lambda runtime context
        
    Returns:
        Response dictionary with statusCode and body
    """
    red_button = RedButtonLambda()
    return red_button.process_request(event)