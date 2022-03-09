## Copyright (c) 2020, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.compartment_ocid
}

resource "oci_mysql_mysql_db_system" "mysql_db_system" {
  admin_password      = var.admin_password
  admin_username      = var.admin_username
  availability_domain = lookup(data.oci_identity_availability_domains.ADs.availability_domains[0], "name")

#   backup_policy {
#     is_enabled        = "true"
#     retention_in_days = "7"
#     window_start_time = "00:00"
#   }
  compartment_id          = var.compartment_ocid
  data_storage_size_in_gb = var.mysql_db_size
  description             = "A MySQL DB System."
  display_name            = var.mysql_db_name
#   fault_domain            = "FAULT-DOMAIN-1"
  hostname_label          = "mysql-db"
  ip_address              = "10.0.1.3"
  maintenance {
    window_start_time = "TUESDAY 07:52"
  }
  port       = "3306"
  port_x     = "33060"
  shape_name = var.mysql_shape
  state      = "ACTIVE"
  subnet_id  = oci_core_subnet.private_subnet.id

  lifecycle {
    ignore_changes = [admin_password, admin_username]
  }
}


