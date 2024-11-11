locals {
  gluejob_count = local.is-production || local.is-development ? 1 : 0
}