################################################################################
# PowerBI Gateway - Environment Configuration
################################################################################

locals {
  environment_configurations = {
    development = {
      powerbi_gateway = {
        instance_type        = "t3a.xlarge"
        root_volume_size     = 100
        data_volume_size     = 300
        enable_monitoring    = true
        ami_maintenance_date = "2025-07-25T00:00:00Z"
        ssh_pub_key          = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDynWDa0u6bP7UCWxjUlEs/xsXpxoH05IBt/bzbX2tFfTBa1qeP6gwLAQMjC2bvnbE6Or0/YXHQFvMdDDUMy9Q2O86KtcBjNiP1BS4DpwHWibflPVkGefYFgicEbpFDoOv+S6xGd1F60LJgszU48TDlBUBK/gNQfjqnoLlvp9+WfPx3DGJfmvyIPp4FMH3SsXRioJGIJ5UvnWgMBX37w/8mHhJpIeUy23kkkbx/3kgmvJzasebEBGhp2m0SqFjqsonh3a+dC9ybR6haTZRWYUhxZ+D8f7lzyBhg+kIO0r9n716BpXHWUZ324JPF7e5b7h4mIFPJ3JZD01Q+9o8Pv/StGHn1TN+UDScskBhf/5PZuhps5ssDznXXc/4XOK0O2Xc8jiIO7JWRLK25cNyOmFTABN+BJXiYIQD8QnS+PhesAsQaWGpA1cw6sxLO8gcMTDojk+QZG3l2bL7+82+zDnXd9bbxbfAA0iY5DxyadIdtvlplVEj1ECynzK8h+vbWRVEUyzsSYb2xmX+N1YsWxmTXDOARm5nK1J0BCoQEoYQLxyx0f8QDfE2GrSyG6uR92UkB5TuTZ4Lj/G2qNQgUM7P55oP2MU4t0l8g/8OR4STjD0cR3LBfIUeeGMV1DTd8HYmKfh7xwBhLLcsNLpO73yfOSKQYIEe0NSTpAdbxgxqdeQ=="
        tags = {
          environment_type = "development"
          criticality      = "low"
          project          = "powerbi-gateway"
        }
      }
    }

    test = {
      powerbi_gateway = {
        instance_type        = "t3a.xlarge"
        root_volume_size     = 100
        data_volume_size     = 300
        enable_monitoring    = true
        ami_maintenance_date = "2025-07-25T00:00:00Z"
        ssh_pub_key          = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCpcqc5sHW6sFSP5uUZTxP1kgl8RGCnzS7ve+WP/7La35fFP0Amoi6SzZeRsw5olXEVM5yppH3N80KIMan09U/fUR2Jam7O5uYbWmqr8utLJXL30HVFle0iywpiXmgRQlW6YgVNWUPQswt7Y5OHnTb3zZ+hyQTbMo5vLT37KBTKGphGSH+yJ+XEeDxksw9vXksHSWunNltuGJ3N3HBm89+q6+f4Ewj+QfTc9z83MWJPvFprgchCCdEkem4Fp2HZMs0wqcSxcoz3dG1eikiaFx2lNm48XJKMpeNKwXNIHI/StiGZVgmdAOye5HfDuZLPlZ+qUMzt2YFwCBfrSgsGGQsG5CT21Ef+hqlOUfCKd68rv8GYX0PlTCHlR9ayUsmbSl9wGsmKottkimPP1vUCUg3cR1lCECZynZEDnq2wK83dIeBn3P76QF/vWzz2z9R4FkvhA9YKd+fgJody1d4OEdMMv/4iMbeRuwKTb9pE8SqeqE4WZgvKu4MTlPYvrVN8FVPtic28jF7QTDU9Xn4G80ixbWKnoMrSIY/81R+CksxBnFxEXJYkFPfw2lkG6nGmDe/wbCo0mLaoFbv2c4DQZaVA96OIp9VhlUrrkyoUzCLnKexvjoEUsC9Ph3XEg0QlWmxLtcCLaC4VMCcZFaha4R7aHwiQBfZx3H1XvlbGbr1HDw=="
        tags = {
          environment_type = "test"
          criticality      = "medium"
          project          = "powerbi-gateway"
        }
      }
    }

    production = {
      powerbi_gateway = {
        instance_type        = "t3a.xlarge"
        root_volume_size     = 100
        data_volume_size     = 300
        enable_monitoring    = true
        ami_maintenance_date = "2025-07-25T00:00:00Z"
        ssh_pub_key          = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDe2fKficUKWk77Ih9K1Qbi/JBDPwj3mkV9i3DKk6MPCW5iRa8L44wzSHHH5Qwj9b7ysP6TL4bkHQTBs+IC30FqLPJkaoPWlXz1J0xuYbKwI9Gir6bAVBIhLUjcQoNvXdLpDDOFo0rBiRDex/U2cO6iUK5iIUSIJmIug1i3W7pR4cSphRMnVhGFWZEg9/tzQt3OpDhuc73NyZrJSvhceiwVwRmMpFZD3tc5wJFgNCOq5snkE2YAmWztOzxKi4dA6i8L1r3Mh86NIbMfxbyD7XhZ8lwjN0yZ8749ihYVrGOfa1mNyW3Nbie2UayBFFWVNj0B+7AuADUwWLODqoJ1kOzwia9S+xJAAMK088dZjEOdqOZwC3QvN+3xvuEL0bnBsMxeZmvShMABajUW/3GjB9nwcwIupNVPxJssZJYai6Cw0yOxboljxWtEhftwZn/B7ReybSaGDv52Ne+RdOtELE2oX0LnBficvo1cf0wYExwmaODLiwvtnuqhqb9+D0MykrqubT6L/bB3gQDbyc6DB4AJ55Lg4n8R73mhCemQBSWnUZm+/jWZUK2AXFmr6UZs25xE8C4PlytMfI6igQYKvVyaO4PBC6G8NPYYbXJATMrMJHTl1kDfYOyw+YMhbU6UMwYC0rzSION1ujXfnDdoFyR33bm1lbzhHOt6XzCMdRsuoQ=="
        tags = {
          environment_type = "production"
          criticality      = "high"
          project          = "powerbi-gateway"
        }
      }
    }
  }
}
