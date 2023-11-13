locals {
  airflow_dag_s3_path          = "dags/"
  airflow_requirements_s3_path = "requirements.txt"

  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      eks_cluster_arn                = "arn:aws:eks:eu-west-2:335889174965:cluster/apps-tools-development"
      eks_certificate_authority_data = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJV04xQi9kT3BSYTB3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TXpBNU1Ua3hPRFU1TVRsYUZ3MHpNekE1TVRZeE9EVTVNVGxhTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUNkLzBaK0JLdFVTWlUvS2dJeVI0aVllMWtFemhGaXBqK1oxbzV1eTVrMGlVU3ZmNm5GWElNWkRmdVcKZWVnVDVpNUhsZ1dRNVBaYm10MkJVbE1DR3lmUWsxa0c4MzNyYXVpUElsdXl5NDh2M0pKZUxOQ2RHQm1wb1Z6LwpoZk1BNUlpejlHRVdZMkVtTFJEMlFOMjlQS3R1VDhFUUVQL3p6WW9Yd0d5QUVUd1RQOTlnMG9lKzJqb3o5ZzZyCm1ZNmFHQTkzazg0QkMvTDBWYVRYZFFMT21vVHBncnRGdnU5VTlXQlBOTmhVTlduVDlMb0NpYktveFhDQzV4eU0KUHJHNXluSHM0OEszWjVVUURXTTY2S1VRcDBVaTdzVndlNkU2TG11eGcvNGFyZ1A1SkptSFJFTkNTQkFvdlBMQwpaZCtYNDF6WGtsOTczVDRXSjI3WUpJcTBNZ1N4QWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJScjk3NU1TS2Y2bzRiUk5IUjhNeXUxRUJmdmFqQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQjdwYjFOakI1cgpWaWcwb1pzOFByY2thTDh2aU1DYUdVQXBRTUlQeE00bnlHREF4VEU5aXNrOWlBc1BkbWlveDNuL1JOVW8wYmpiCm8rRnYvWUxXTlJCS0xxdWpKVWVWYUoyZzVIVDlQZVQvVEdsZzhuNkgyRzFHLzFmR3UybllFdVk2S2c3bzJadGcKRG1QazJFUzAwTVkzYkgrN2VoYURoaldpbzl1N2RQVGVsdnRVaU5Kbkd0TlAwMVZMUXJhK0t6SHZpd3N2VFkrYgo5d1VsQTIzYnFNK1cxQ0hTajdSbzFFckpBVEZXamdmVnZ2UUlYRnN3TmFsemM2VW1VN3ZPSEI3cDE3MEh3WGI2ClVOd2RVek4rc2JKRElodHhwV25KOXFtVlhkVnlycTJ5Q2V1M2FKdFFDMVltcWVaZFIwOW1mSjhaS2ZMMTlpTEoKTS9rU0NvZE5ueW53Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
      eks_server                     = "https://BEE86BED6494692D4ED31C2ED2319E13.gr7.eu-west-2.eks.amazonaws.com"
      eks_cluster_name               = "apps-tools-development"
      route53_zone                   = "apps-tools.development.data-platform.service.justice.gov.uk"
      ses_domain_identity            = "apps-tools.development.data-platform.service.justice.gov.uk"
      auth0_log_streams = {
        "dev-analytics-moj" = {
          event_source_name = "aws.partner/auth0.com/dev-analytics-moj-20c1595d-28e2-4822-9e1c-cb29ac38c7d2/auth0.logs"
        }
        "ministryofjustice-data-platform-development" = {
          event_source_name = "aws.partner/auth0.com/ministryofjustice-data-platform-development-a628362c-f79b-46e9-9604-7c9861565a1b/auth0.logs"
        }
      }
    }
    production = {
      eks_cluster_arn                = "arn:aws:eks:eu-west-1:312423030077:cluster/production-dBSvju9Y"
      eks_certificate_authority_data = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM1ekNDQWMrZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJeE1EZ3lOREV5TVRBd05Gb1hEVE14TURneU1qRXlNVEF3TkZvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTGtyCllrNVhVT3VyU3M0T2o3aE5XRE0zSC9vUnhUMmY0c014eGJoMEEwM010OXQ5SUtBaWM2TFpiMlZJd3VobG14bUIKaVhuSEtXSHREbi85NUwwdEgvWURnN3VFSXVMa2xMS3F0NjRVWlFFWHNocElaakxpNFU1bW03WWttT1N4VjFYSQo4bXJ4VEhaRGZ1NHZwdURUSWdmR2szTE8rTXBBZVgrTFNFM1JVSWR4UFo1eDVzYloyU29NWkFYekRnaHEzOU9RCjY3WVNFdmRYS1Bkd1JDUnR0d2k4OGVuOGpxanRZMFB5dUVaMVQzRjVPeWhBMjNQWVBMam10aWt2akNwMmNKOTkKZnhUNG1NNWsyUUlxQmxZWTRzR0s3dzhTL1I2VGxtL1g4KzBjeWhyU2FmMjh2dUNVL0dXZVJ6MWhYa05rV2FKTQpkampuWElzeFRkc0tGc1RUMzVVQ0F3RUFBYU5DTUVBd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZQVkpZMGlHcW9RODlmMy9sbkNsdUQ4NnZvUDNNQTBHQ1NxR1NJYjMKRFFFQkN3VUFBNElCQVFBb2tScklHRzRWbVBGMnBhV3dSdEdhU01NVnBaWDdRRGhEL0tSajY5NXZLOU1YaDJnSgpPeWR3enRJd2tMalNjZUhaZTJocE9DNkt3VUxMbFJYRzJRbXhzUnJtaEM5NU8xWEM1cURZV2JFRUoxUnpsUkJGCkdQT1FMQ0tWTnc4b21KTlRXcDdTTDgxeFBiZCtnNm1KSlB3UHQ2cVJHNTBaMnRVSzZVRnZSbVRUcXl3Z1U4UXkKemp5cFJMVkJtQWc3Tkw3MW9zS0x4T25qUHRHNDl4eVNTVExQaGpDSzlIUnM5bXJDaVJ0RWo1b2EwUHY3d2hIOQpWQS8yYVVmRTA5cjg4dXFYWHIvZlNoY1FXSlhmU1gvYVVIbFZwK0NJU2tHUkJscmFKc3ZHSlZ3UWJRR3ZvTGZmCnMyTFo3M1EzbHpDM2VOajJ6WTcrbTdlazVLOUJEc29oK2lWeAotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
      eks_server                     = "https://EB06461747C1D40013EE978C4D8D1755.gr7.eu-west-1.eks.amazonaws.com"
      eks_cluster_name               = "production-dBSvju9Y"
      route53_zone                   = "apps-tools.data-platform.service.justice.gov.uk"
      ses_domain_identity            = "apps-tools.data-platform.service.justice.gov.uk"
      auth0_log_streams = {
        "alpha-analytics-moj" = {
          event_source_name = "aws.partner/auth0.com/alpha-analytics-moj-5246b1ce-4ea2-45ab-9c2d-1414d6ff608a/auth0.logs"
        }
        "ministryofjustice-data-platform" = {
          event_source_name = "aws.partner/auth0.com/alpha-analytics-moj-5246b1ce-4ea2-45ab-9c2d-1414d6ff608a/auth0.logs"
        }
      }
    }
  }
}
