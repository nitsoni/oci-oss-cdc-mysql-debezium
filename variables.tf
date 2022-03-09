## Copyright (c) 2020, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable "tenancy_ocid" {}
variable "current_user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "compartment_ocid" {}
variable "region" {}

variable "admin_password" {}
variable "admin_username" {}

variable "mysql_db_size" {
  default = 50
}

variable "mysql_db_name" {
  default = "SampleDB"
}

variable "mysql_shape" {
  default = "MySQL.VM.Standard.E3.1.8GB"
}

# OS Images
variable "instance_os" {
  description = "Operating system for compute instances"
  default     = "Oracle Linux"
}

variable "linux_os_version" {
  description = "Operating system version for all Linux instances"
  default     = "7.9"
}

variable "instance_shape" {
  default = "VM.Standard.E3.Flex"
}

variable "instance_flex_shape_ocpus" {
  default = 1
}

variable "instance_flex_shape_memory" {
  default = 10
}

variable "public_ssh_key" {
  default = ""
}

variable "generate_public_ssh_key" {
  default = true
}

variable "private_ssh_key_path" {
  default = ""
}

# Dictionary Locals
locals {
  compute_flexible_shapes = [
    "VM.Standard.E3.Flex",
    "VM.Standard.E4.Flex",
    "VM.Standard.A1.Flex",
    "VM.Optimized3.Flex"
  ]
}

# Checks if is using Flexible Compute Shapes
locals {
  is_flexible_node_shape = contains(local.compute_flexible_shapes, var.instance_shape)
}

