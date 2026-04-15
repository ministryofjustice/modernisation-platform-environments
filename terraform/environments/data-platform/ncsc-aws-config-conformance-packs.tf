module "ncsc_aws_config_conformance_packs" {
  source = "../../modules/ncsc-aws-config-conformance-packs"
}

moved {
  from = aws_config_conformance_pack.main["ncsc-cloud-security-principles"]
  to   = module.ncsc_aws_config_conformance_packs.aws_config_conformance_pack.this["ncsc-cloud-security-principles"]
}

moved {
  from = aws_config_conformance_pack.main["ncsc-cyber-assessment-framework"]
  to   = module.ncsc_aws_config_conformance_packs.aws_config_conformance_pack.this["ncsc-cyber-assessment-framework"]
}
