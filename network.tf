## Copyright (c) 2020, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_core_vcn" "vcn" {
  cidr_block     = "10.0.0.0/16"
  dns_label      = "vcn"
  compartment_id = var.compartment_ocid
  display_name   = "mysql_vcn"
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  display_name   = "igw"
  vcn_id         = oci_core_vcn.vcn.id
}

resource oci_core_nat_gateway nat_gateway {
  block_traffic = "false"
  compartment_id = var.compartment_ocid
  display_name = "NAT Gateway MySQL VCN"
  vcn_id = oci_core_vcn.vcn.id
}

data oci_core_services core_services {}

locals {
  all_services = [for service in data.oci_core_services.core_services.services : service if contains(regexall("All.*?",service.name), "All") && contains(regexall("Services In Oracle Services Network",service.name), "Services In Oracle Services Network")]
}

resource oci_core_service_gateway service_gateway {
  compartment_id = var.compartment_ocid
  display_name = "Service Gateway MySQL VCN"
  services {
    service_id = local.all_services[0].id
  }
  vcn_id = oci_core_vcn.vcn.id
}

resource "oci_core_route_table" "route_table" {
  compartment_id = var.compartment_ocid
  display_name   = "Route Table for Private Subnet MySQL VCN"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat_gateway.id
  }
  # route_rules {
  #   destination       = "10.0.1.0/24"//"all-nrt-services-in-oracle-services-network"
  #   destination_type  = "SERVICE_CIDR_BLOCK"
  #   network_entity_id = oci_core_service_gateway.service_gateway.id
  # }
  vcn_id = oci_core_vcn.vcn.id
}

resource "oci_core_default_route_table" "default_route_table" {
  display_name               = "Default Route Table for MySQL VCN"
  manage_default_resource_id = oci_core_vcn.vcn.default_route_table_id
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

# resource "oci_core_dhcp_options" "dhcpoptions1" {
#   compartment_id = var.compartment_ocid
#   vcn_id         = oci_core_vcn.vcn.id
#   display_name   = "dhcpoptions1"

#   // required
#   options {
#     type = "DomainNameServer"
#     server_type = "VcnLocalPlusInternet"
#   }

# }

resource "oci_core_subnet" "public_subnet" {
  cidr_block                 = "10.0.0.0/24"
  compartment_id             = var.compartment_ocid
  dhcp_options_id            = oci_core_vcn.vcn.default_dhcp_options_id
  display_name               = "Public Subnet MySQL VCN"
  dns_label                  = "sub01251514400"
  prohibit_public_ip_on_vnic = "false"
  route_table_id             = oci_core_vcn.vcn.default_route_table_id
  security_list_ids = [
    oci_core_vcn.vcn.default_security_list_id,
  ]
  vcn_id = oci_core_vcn.vcn.id
}

resource "oci_core_subnet" "private_subnet" {
  cidr_block                 = "10.0.1.0/24"
  compartment_id             = var.compartment_ocid
  dhcp_options_id            = oci_core_vcn.vcn.default_dhcp_options_id
  display_name               = "Private Subnet MySQL VCN"
  dns_label                  = "sub01251514401"
  prohibit_public_ip_on_vnic = "true"
  route_table_id             = oci_core_route_table.route_table.id
  security_list_ids = [
    oci_core_security_list.security_list_private.id,
  ]
  vcn_id = oci_core_vcn.vcn.id
}

resource oci_core_security_list security_list_private {
  compartment_id = var.compartment_ocid
  defined_tags = {}
  display_name = "Security List for Private Subnet MySQL VCN"
  egress_security_rules {
    destination = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol = "all"
    stateless = "false"
  }
  freeform_tags = {}
  ingress_security_rules {
    protocol = "6"
    source = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    stateless = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }
  ingress_security_rules {
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol = "1"
    source = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless = "false"
  }
  ingress_security_rules {
    icmp_options {
      code = "-1"
      type = "3"
    }
    protocol = "1"
    source = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    stateless = "false"
  }
  ingress_security_rules {
    description = "mysql"
    protocol = "6"
    source = "10.0.0.0/24"
    source_type = "CIDR_BLOCK"
    stateless = "false"
    tcp_options {
      max = "3306"
      min = "3306"
    }
  }
  ingress_security_rules {
    description = "mysql"
    protocol = "6"
    source = "10.0.0.0/24"
    source_type = "CIDR_BLOCK"
    stateless = "false"
    tcp_options {
      max = "33060"
      min = "33060"
    }
  }
  vcn_id = oci_core_vcn.vcn.id
}



