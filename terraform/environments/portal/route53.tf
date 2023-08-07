###############################################################################################################
############################              OAM Route 53 records                  ###############################
###############################################################################################################

### http://portal-oam-internal.aws.prd.legalservices.gov.uk:80 → Now points to Internal ALB to OHS
### https://portal-oam-console.aws.prd.legalservices.gov.uk:443
### portal-oam-admin.aws.prd.legalservices.gov.uk
### portal-oam1-ms.aws.prd.legalservices.gov.uk
### portal-oam2-ms.aws.prd.legalservices.gov.uk


resource "aws_route53_record" "oam_internal" {
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-oam-internal.${data.aws_route53_zone.portal-dev-private.name}"
  type     = "A"

  alias {
    name                   = aws_lb.internal.dns_name
    zone_id                = aws_lb.internal.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "oam_console" {
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-oam-console.${data.aws_route53_zone.portal-dev-private.name}"
  type     = "A"

  alias {
    name                   = aws_lb.internal.dns_name
    zone_id                = aws_lb.internal.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "oam_admin" {
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-oam-admin.${data.aws_route53_zone.portal-dev-private.name}"
  type     = "A"
  ttl      = 60
  records  = [aws_instance.oam_instance_1.private_ip]
}

resource "aws_route53_record" "oam1_nonprod" {
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-oam1-ms.${data.aws_route53_zone.portal-dev-private.name}" # Correspond to portal-oam1-ms.aws.[env].legalservices.gov.uk
  type     = "A"
  ttl      = 60
  records  = [aws_instance.oam_instance_1.private_ip]
}

resource "aws_route53_record" "oam2_prod" {
  count    = contains(["development", "testing"], local.environment) ? 0 : 1
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-oam2-ms.${data.aws_route53_zone.portal-dev-private.name}" # Correspond to portal-oam2-ms.aws.[env].legalservices.gov.uk
  type     = "A"
  ttl      = 60
  records  = [aws_instance.oam_instance_2[0].private_ip]
}


###############################################################################################################
############################              OIM Route 53 records                  ###############################
###############################################################################################################

### http://portal-oim-internal.aws.prd.legalservices.gov.uk:80 → Now points to Internal ALB to OHS
### https://portal-oim-console.aws.prd.legalservices.gov.uk:443
### portal-oim-admin.aws.prd.legalservices.gov.uk
### portal-oim1-ms.aws.prd.legalservices.gov.uk
### portal-oim2-ms.aws.prd.legalservices.gov.uk
### portal-bip1-ms.aws.prd.legalservices.gov.uk
### portal-bip2-ms.aws.prd.legalservices.gov.uk
### portal-soa1-ms.aws.prd.legalservices.gov.uk
### portal-soa2-ms.aws.prd.legalservices.gov.uk


resource "aws_route53_record" "oim_internal" {
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-oim-internal.${data.aws_route53_zone.portal-dev-private.name}"
  type     = "A"

  alias {
    name                   = aws_lb.internal.dns_name
    zone_id                = aws_lb.internal.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "oim_console" {
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-oim-console.${data.aws_route53_zone.portal-dev-private.name}"
  type     = "A"

  alias {
    name                   = aws_lb.internal.dns_name
    zone_id                = aws_lb.internal.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "oim_admin" {
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-oim-admin.${data.aws_route53_zone.portal-dev-private.name}" 
  type     = "A"
  ttl      = 60
  records  = [aws_instance.oim_instance_1.private_ip]
}

resource "aws_route53_record" "oim1_nonprod" {
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-oim1-ms.${data.aws_route53_zone.portal-dev-private.name}" # Correspond to portal-oim1-ms.aws.[env].legalservices.gov.uk
  type     = "A"
  ttl      = 60
  records  = [aws_instance.oim_instance_1.private_ip]
}

resource "aws_route53_record" "oim2_prod" {
  count    = contains(["development", "testing"], local.environment) ? 0 : 1
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-oim2-ms.${data.aws_route53_zone.portal-dev-private.name}" # Correspond to portal-oim2-ms.aws.[env].legalservices.gov.uk
  type     = "A"
  ttl      = 60
  records  = [aws_instance.oim_instance_2[0].private_ip]
}

resource "aws_route53_record" "bip1_nonprod" {
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-bip1-ms.${data.aws_route53_zone.portal-dev-private.name}" # Correspond to portal-bip1-ms.aws.[env].legalservices.gov.uk
  type     = "A"
  ttl      = 60
  records  = [aws_instance.oim_instance_1.private_ip]
}

resource "aws_route53_record" "bip2_prod" {
  count    = contains(["development", "testing"], local.environment) ? 0 : 1
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-bip2-ms.${data.aws_route53_zone.portal-dev-private.name}" # Correspond to portal-bip2-ms.aws.[env].legalservices.gov.uk
  type     = "A"
  ttl      = 60
  records  = [aws_instance.oim_instance_2[0].private_ip]
}

resource "aws_route53_record" "soa1_nonprod" {
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-soa1-ms.${data.aws_route53_zone.portal-dev-private.name}" # Correspond to portal-soa1-ms.aws.[env].legalservices.gov.uk
  type     = "A"
  ttl      = 60
  records  = [aws_instance.oim_instance_1.private_ip]
}

resource "aws_route53_record" "soa2_prod" {
  count    = contains(["development", "testing"], local.environment) ? 0 : 1
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-soa2-ms.${data.aws_route53_zone.portal-dev-private.name}" # Correspond to portal-soa2-ms.aws.[env].legalservices.gov.uk
  type     = "A"
  ttl      = 60
  records  = [aws_instance.oim_instance_2[0].private_ip]
}


###############################################################################################################
############################              OID Route 53 records                  ###############################
###############################################################################################################

### portal-oid.aws.prd.legalservices.gov.uk


resource "aws_route53_record" "oid_internal" {
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-oid.${data.aws_route53_zone.portal-dev-private.name}"
  type     = "A"

  alias {
    name                   = aws_lb.internal.dns_name
    zone_id                = aws_lb.internal.zone_id
    evaluate_target_health = true
  }
}


###############################################################################################################
#########################              IDM / ODS Route 53 records               ###############################
###############################################################################################################

### http://portal-idm-console.aws.prd.legalservices.gov.uk → Now points to Internal ALB to OHS
### portal-idm-admin.aws.prd.legalservices.gov.uk
### portal-ods1-ms.aws.prd.legalservices.gov.uk
### portal-ods2-ms.aws.prd.legalservices.gov.uk


resource "aws_route53_record" "idm_console" {
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-idm-console.${data.aws_route53_zone.portal-dev-private.name}"
  type     = "A"

  alias {
    name                   = aws_lb.internal.dns_name
    zone_id                = aws_lb.internal.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "idm_admin" {
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-idm-admin.${data.aws_route53_zone.portal-dev-private.name}" 
  type     = "A"
  ttl      = 60
  records  = [aws_instance.idm_instance_1.private_ip]
}

resource "aws_route53_record" "ods1_nonprod" {
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-ods1-ms.${data.aws_route53_zone.portal-dev-private.name}" # Correspond to portal-ods1-ms.aws.[env].legalservices.gov.uk
  type     = "A"
  ttl      = 60
  records  = [aws_instance.idm_instance_1.private_ip]
}

resource "aws_route53_record" "ods2_prod" {
  count    = contains(["development", "testing"], local.environment) ? 0 : 1
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-ods2-ms.${data.aws_route53_zone.portal-dev-private.name}" # Correspond to portal-ods2-ms.aws.[env].legalservices.gov.uk
  type     = "A"
  ttl      = 60
  records  = [aws_instance.idm_instance_2[0].private_ip]
}


###############################################################################################################
############################              OHS Route 53 records                  ###############################
###############################################################################################################

# portal-ohs-internal.aws.prd.legalservices.gov.uk
# portal-ohs1.aws.prd.legalservices.gov.uk
# portal-ohs2.aws.prd.legalservices.gov.uk


resource "aws_route53_record" "ohs_internal" {
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-ohs-internal.${data.aws_route53_zone.portal-dev-private.name}"
  type     = "A"

  alias {
    name                   = aws_lb.internal.dns_name
    zone_id                = aws_lb.internal.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "ohs1_nonprod" {
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-ohs1.${data.aws_route53_zone.portal-dev-private.name}" # Correspond to portal-ohs1.aws.[env].legalservices.gov.uk
  type     = "A"
  ttl      = 60
  records  = [aws_instance.ohs_instance_1.private_ip]
}

resource "aws_route53_record" "ods2_prod" {
  count    = contains(["development", "testing"], local.environment) ? 0 : 1
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-ohs2.${data.aws_route53_zone.portal-dev-private.name}" # Correspond to portal-ohs2.aws.[env].legalservices.gov.uk
  type     = "A"
  ttl      = 60
  records  = [aws_instance.ohs_instance_2[0].private_ip]
}