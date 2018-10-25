data "oci_identity_availability_domains" "availability_domains" {
  compartment_id = "${var.tenancy_ocid}"
}

variable "cidr_block" {
  default = "10.0.0.0/16"
}

resource "oci_core_virtual_network" "virtual_network" {
  cidr_block     = "${var.cidr_block}"
  compartment_id = "${var.compartment_ocid}"
  display_name   = "virtual_network"
  dns_label      = "cloudera"
}

resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "internet_gateway"
  vcn_id         = "${oci_core_virtual_network.virtual_network.id}"
}

resource "oci_core_route_table" "route_table" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.virtual_network.id}"
  display_name   = "route_table"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = "${oci_core_internet_gateway.internet_gateway.id}"
  }
}

resource "oci_core_security_list" "public" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "public"
  vcn_id         = "${oci_core_virtual_network.virtual_network.id}"

  egress_security_rules = [{
    destination = "0.0.0.0/0"
    protocol    = "6"
  }]

  ingress_security_rules = [{
    tcp_options {
      "max" = 7180
      "min" = 7180
    }

    protocol = "6"
    source   = "0.0.0.0/0"
  }]

  ingress_security_rules = [{
    tcp_options {
      "max" = 80
      "min" = 80
    }

    protocol = "6"
    source   = "0.0.0.0/0"
  }]

  ingress_security_rules = [{
    tcp_options {
      "max" = 8888
      "min" = 8888
    }

    protocol = "6"
    source   = "0.0.0.0/0"
  }]

  ingress_security_rules = [{
    tcp_options {
      "max" = 22
      "min" = 22
    }

    protocol = "6"
    source   = "0.0.0.0/0"
  }]

  ingress_security_rules = [{
    protocol = "6"
    source   = "${var.cidr_block}"
  }]
}

resource "oci_core_subnet" "public" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[0], "name")}"
  cidr_block          = "${var.cidr_block}"
  display_name        = "public"
  dns_label           = "public"
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_virtual_network.virtual_network.id}"
  route_table_id      = "${oci_core_route_table.route_table.id}"
  security_list_ids   = ["${oci_core_security_list.public.id}"]
  dhcp_options_id     = "${oci_core_virtual_network.virtual_network.default_dhcp_options_id}"
}
