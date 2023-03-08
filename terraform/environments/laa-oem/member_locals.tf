#### This file can be used to store locals specific to the member account ####

locals {
  ami_app            = "ami-0c6f19670d053404e"
  ami_db             = "ami-0c6f19670d053404e"
  application_name   = "laa-oem"
  cidr_lz_workspaces = "10.200.0.0/20"
  vol_snap_app_app   = "snap-0345307239f01c8ab"
  vol_snap_app_inst  = "snap-09f32d294decca5ca"
  vol_snap_db_app    = "snap-0abed8d20d4ad01d4"
  vol_snap_db_inst   = "snap-0bc2bc6b4d11534aa"
  vol_snap_db_dbf    = "snap-0611d48ac056efe54"
  vol_snap_db_redo   = "snap-0cf269973426fa7c0"
  vol_snap_db_arch   = "snap-02b71be8ef196aebc"
}