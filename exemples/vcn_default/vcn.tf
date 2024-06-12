// Copyright (c) 2017, 2024, Oracle and/or its affiliates. All rights reserved.
// Licensed under the Mozilla Public License v2.0

# VCN comes with default route table, security list and DHCP options

variable "tenancy_ocid" {
  default = "ocid1.tenancy.oc1..aaaaaaaawquag7eeulmm6e2yoykcvigene6piosc6rwgglznmt4d5iubifuq"
}

variable "user_ocid" {
  default = "ocid1.user.oc1..aaaaaaaaqcw5nynoejzkgqyr6frdxzybhrmnxqyzdvqh2t7ft2cevbbde37q"
}

variable "fingerprint" {
  default = "be:7d:65:fd:33:8a:da:ce:bd:56:e9:72:69:58:43:8f"
}

variable "private_key_path" {
  default = "/Users/Silvio/Documents/OCI/RM/oci-terraform/exemples/private.pem"
}

variable "compartment_ocid" {
  default = "ocid1.compartment.oc1..aaaaaaaayyfw5s76wsgg2d6td4ywm3l5xwkuckkh6cmahmjq7mvnltyazfyq"
}

variable "region" {
  default = "sa-saopaulo-1"
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

resource "oci_core_vcn" "vcn1" {
  cidr_block     = "10.0.0.0/16"
  dns_label      = "vcn1"
  compartment_id = var.compartment_ocid
  display_name   = "vcn1"
}

resource "oci_core_internet_gateway" "test_internet_gateway" {
  compartment_id = var.compartment_ocid
  display_name   = "testInternetGateway"
  vcn_id         = oci_core_vcn.vcn1.id
}

resource "oci_core_default_route_table" "default_route_table" {
  manage_default_resource_id = oci_core_vcn.vcn1.default_route_table_id
  display_name               = "defaultRouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.test_internet_gateway.id
  }
}

resource "oci_core_route_table" "route_table1" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn1.id
  display_name   = "routeTable1"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.test_internet_gateway.id
  }
}

resource "oci_core_default_dhcp_options" "default_dhcp_options" {
  manage_default_resource_id = oci_core_vcn.vcn1.default_dhcp_options_id
  display_name               = "defaultDhcpOptions"

  // required
  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }

  // optional
  options {
    type                = "SearchDomain"
    search_domain_names = ["abc.com"]
  }
}

resource "oci_core_dhcp_options" "dhcp_options1" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn1.id
  display_name   = "dhcpOptions1"

  // required
  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }

  // optional
  options {
    type                = "SearchDomain"
    search_domain_names = ["test123.com"]
  }
}

resource "oci_core_default_security_list" "default_security_list" {
  manage_default_resource_id = oci_core_vcn.vcn1.default_security_list_id
  display_name               = "defaultSecurityList"

  // allow outbound tcp traffic on all ports
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"
  }

  // allow outbound udp traffic on a port range
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "17" // udp
    stateless   = true

    udp_options {
      min = 319
      max = 320
    }
  }

  // allow inbound ssh traffic
  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 22
      max = 22
    }
  }

  // allow inbound icmp traffic of a specific type
  ingress_security_rules {
    protocol  = 1
    source    = "0.0.0.0/0"
    stateless = true

    icmp_options {
      type = 3
      code = 4
    }
  }
}

