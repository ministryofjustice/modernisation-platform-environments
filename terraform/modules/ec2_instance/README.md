# `ec2_instance` module

Terraform module for standing up a single EC2 instance

## EBS Volumes

If you specify nothing, the volumes will be derived from those in the AMI image
and will be created as a separate resource to allow easy resizing.

You can optionally assign a "label" to the volume to make the volumes easy
to identify, e.g.

```
ebs_volumes = {
  "/dev/sde" = { label = "data" }  # DATA01
  "/dev/sdf" = { label = "data" }  # DATA02
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

See `environments/nomis` for usage examples.
