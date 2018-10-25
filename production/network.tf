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
      "max" = 19888
      "min" = 19888
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

resource "oci_core_security_list" "private" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "private"
  vcn_id         = "${oci_core_virtual_network.virtual_network.id}"

  egress_security_rules = [{
    destination = "0.0.0.0/0"
    protocol    = "6"
  }]

  egress_security_rules = [{
    protocol    = "6"
    destination = "${var.cidr_block}"
  }]

  ingress_security_rules = [{
    protocol = "6"
    source   = "${var.cidr_block}"
  }]
}

resource "oci_core_subnet" "public" {
  count               = "3"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[count.index],"name")}"
  cidr_block          = "${cidrsubnet(var.cidr_block, 8, count.index)}"
  display_name        = "public${count.index}"
  dns_label           = "public${count.index}"
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_virtual_network.virtual_network.id}"
  route_table_id      = "${oci_core_route_table.route_table.id}"
  security_list_ids   = ["${oci_core_security_list.public.id}"]
  dhcp_options_id     = "${oci_core_virtual_network.virtual_network.default_dhcp_options_id}"
}

resource "oci_core_subnet" "private" {
  count               = "3"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[count.index],"name")}"
  cidr_block          = "${cidrsubnet(var.cidr_block, 8, count.index+3)}"
  display_name        = "private${count.index}"
  dns_label           = "private${count.index}"
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_virtual_network.virtual_network.id}"
  route_table_id      = "${oci_core_route_table.route_table.id}"
  security_list_ids   = ["${oci_core_security_list.private.id}"]
  dhcp_options_id     = "${oci_core_virtual_network.virtual_network.default_dhcp_options_id}"
}
