resource "aws_route53_zone" "private_uat" {
  name = "aws.uat.legalservices.gov.uk"

  vpc {
    vpc_id = module.vpc.vpc_id
  }

  #   lifecycle {
  #     ignore_changes = [vpc]
  #   }
}

# # resource "aws_route53_zone_association" "private_uat" {
# #   zone_id = aws_route53_zone.private_uat.zone_id
# #   vpc_id  = module.vpc.vpc_id
# # }

#############################
# Records for RDS
#############################

resource "aws_route53_record" "iadb" {
  zone_id = aws_route53_zone.private_uat.zone_id
  name    = "db-portal-iadb.${aws_route53_zone.private_uat.name}"
  type    = "CNAME"
  ttl     = 60
  records = [aws_db_instance.iadb.address]
}

resource "aws_route53_record" "igdb" {
  zone_id = aws_route53_zone.private_uat.zone_id
  name    = "db-portal-igdb.${aws_route53_zone.private_uat.name}"
  type    = "CNAME"
  ttl     = 60
  records = [aws_db_instance.igdb.address]
}

#############################
# Records for OHS
#############################

resource "aws_route53_record" "ohs1" {
  zone_id = aws_route53_zone.private_uat.zone_id
  name    = "portal-ohs1.${aws_route53_zone.private_uat.name}"
  type    = "A"
  ttl     = 60
  records = [aws_instance.ohs_instance_1.private_ip]
}

resource "aws_route53_record" "ohs_internal" {
  zone_id = aws_route53_zone.private_uat.zone_id
  name    = "portal-ohs-internal.${aws_route53_zone.private_uat.name}"
  type    = "A"
  alias {
    name                   = aws_lb.internal.dns_name
    zone_id                = aws_lb.internal.zone_id
    evaluate_target_health = true
  }
}

#############################
# Records for IDM
#############################

resource "aws_route53_record" "idm_admin" {
  zone_id = aws_route53_zone.private_uat.zone_id
  name    = "portal-idm-admin.${aws_route53_zone.private_uat.name}"
  type    = "A"
  ttl     = 60
  records = [aws_instance.idm_instance_1.private_ip]
}

resource "aws_route53_record" "idm_ms" {
  zone_id = aws_route53_zone.private_uat.zone_id
  name    = "portal-ods1-ms.${aws_route53_zone.private_uat.name}"
  type    = "A"
  ttl     = 60
  records = [aws_instance.idm_instance_1.private_ip]
}

resource "aws_route53_record" "idm_console" {
  zone_id = aws_route53_zone.private_uat.zone_id
  name    = "portal-idm-console.${aws_route53_zone.private_uat.name}"
  type    = "A"
  alias {
    name                   = aws_lb.internal.dns_name
    zone_id                = aws_lb.internal.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "oid" {
  zone_id = aws_route53_zone.private_uat.zone_id
  name    = "portal-oid.${aws_route53_zone.private_uat.name}"
  type    = "A"
  alias {
    name                   = aws_elb.idm_lb.dns_name
    zone_id                = aws_elb.idm_lb.zone_id
    evaluate_target_health = true
  }
}

#############################
# Records for OIM
#############################

resource "aws_route53_record" "oim_admin" {
  zone_id = aws_route53_zone.private_uat.zone_id
  name    = "portal-oim-admin.${aws_route53_zone.private_uat.name}"
  type    = "A"
  ttl     = 60
  records = [aws_instance.oim_instance_1.private_ip]
}

resource "aws_route53_record" "oim_console" {
  zone_id = aws_route53_zone.private_uat.zone_id
  name    = "portal-oim-console.${aws_route53_zone.private_uat.name}"
  type    = "A"
  alias {
    name                   = aws_lb.internal.dns_name
    zone_id                = aws_lb.internal.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "oim1_ms" {
  zone_id = aws_route53_zone.private_uat.zone_id
  name    = "portal-oim1-ms.${aws_route53_zone.private_uat.name}"
  type    = "A"
  ttl     = 60
  records = [aws_instance.oim_instance_1.private_ip]
}

resource "aws_route53_record" "bip1_ms" {
  zone_id = aws_route53_zone.private_uat.zone_id
  name    = "portal-bip1-ms.${aws_route53_zone.private_uat.name}"
  type    = "A"
  ttl     = 60
  records = [aws_instance.oim_instance_1.private_ip]
}

resource "aws_route53_record" "soa1_ms" {
  zone_id = aws_route53_zone.private_uat.zone_id
  name    = "portal-soa1-ms.${aws_route53_zone.private_uat.name}"
  type    = "A"
  ttl     = 60
  records = [aws_instance.oim_instance_1.private_ip]
}

resource "aws_route53_record" "oim_internal" {
  zone_id = aws_route53_zone.private_uat.zone_id
  name    = "portal-oim-internal.${aws_route53_zone.private_uat.name}"
  type    = "A"
  alias {
    name                   = aws_lb.internal.dns_name
    zone_id                = aws_lb.internal.zone_id
    evaluate_target_health = true
  }
}

#############################
# Records for OAM
#############################

resource "aws_route53_record" "oam1_ms" {
  zone_id = aws_route53_zone.private_uat.zone_id
  name    = "portal-oam1-ms.${aws_route53_zone.private_uat.name}"
  type    = "A"
  ttl     = 60
  records = [aws_instance.oam_instance_1.private_ip]
}

resource "aws_route53_record" "oam1_admin" {
  zone_id = aws_route53_zone.private_uat.zone_id
  name    = "portal-oam-admin.${aws_route53_zone.private_uat.name}"
  type    = "A"
  ttl     = 60
  records = [aws_instance.oam_instance_1.private_ip]
}

resource "aws_route53_record" "oam_console" {
  zone_id = aws_route53_zone.private_uat.zone_id
  name    = "portal-oam-console.${aws_route53_zone.private_uat.name}"
  type    = "A"
  alias {
    name                   = aws_lb.internal.dns_name
    zone_id                = aws_lb.internal.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "oam_internal" {
  zone_id = aws_route53_zone.private_uat.zone_id
  name    = "portal-oam-internal.${aws_route53_zone.private_uat.name}"
  type    = "A"
  alias {
    name                   = aws_lb.internal.dns_name
    zone_id                = aws_lb.internal.zone_id
    evaluate_target_health = true
  }
}
