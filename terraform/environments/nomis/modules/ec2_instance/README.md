# ec2-instance module

Terraform module for standing up a single EC2 instance

## EBS Volumes

If you specify nothing, the volumes will be derived from those in the AMI image
and will be created as a separate resource to allow easy resizing.

You can optionally assign a "label" to the volume to make the volumes easy
to identify, e.g.

```
ebs_volumes = {
  "/dev/sde" = { label = "data" }  # DATA01
  "/dev/sdf" = { label = "data" }  # DATA02
}
```

The label will then be included in the tag:Name. You can also override the
default AMI settings. If all the volumes with the same label have the same
settings, set like this:

```
ebs_volume_config = {
  data = {
    iops       = 3000
    throughput = 125
    total_size = 200
  }
}
```

The size of each volume is `total_size` divided by the number of volumes with that label.

Alternatively, override settings directly within the `ebs_volumes` variable.

```
ebs_volumes = {
  "/dev/sde" = { size = 100 }
  "/dev/sdf" = { size = 150 }
}
```

## Restoring a database backup from an s3 bucket to a database instance

Using ec2-database.tf (which uses the ec2-instance module) you can restore a database backup from an s3 bucket to a database instance.

To create an EC2 instance where you are restoring backup files from a directory (e.g. CNOMT1_20211214) you need to include a tag 's3-db-restore-dir' with the value `<db_name>_YYYYMMDD` in the relevant environment (locals{} in nomis-\*.tf). This will run the db_restore role in [modernisation-platforms-configuration-management](https://github.com/ministryofjustice/modernisation-platform-configuration-management) assuming the backup exist in `nomis-db-backup-bucket20220131102905687200000001` s3 bucket.

### Example db EC2 instance with s3-db-restore-dir tag

e.g. nomis-test.tf

```
      t1-nomis-db-1 = {
        tags = {
          server-type = "nomis-db"
          description = "T1 NOMIS test database to replace Azure T1PDL0009"
          oracle-sids = "CNOMT1"
          monitored   = false
          always-on   = true
          s3-db-restore-dir = "CNOMT1_20211214"
        }
        ami_name = "nomis_rhel_7_9_oracledb_11_2_release_2022-10-07T12-48-08.562Z"
        instance = {
          disable_api_termination = true
        }
        ebs_volume_config = {
          data  = { total_size = 200 }
          flash = { total_size = 2 }
        }
      }
```

NOTE: oracle-sids is used earlier in the setup and there may be more then one in some cases.
