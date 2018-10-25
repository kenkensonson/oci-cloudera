resource "oci_core_instance" "utility" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[0],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "cdh-utility"
  hostname_label      = "cdh-utility"
  shape               = "${var.utility["shape"]}"
  subnet_id           = "${oci_core_subnet.public.*.id[0]}"

  source_details {
    source_type = "image"
    source_id   = "${var.images[var.region]}"
  }

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data = "${base64encode(format("%s\n%s\n",
      "#!/usr/bin/env bash",
      file("../scripts/shared.sh")
    ))}"
  }
}

data "oci_core_vnic_attachments" "utility_vnics" {
  compartment_id      = "${var.compartment_ocid}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[0],"name")}"
  instance_id         = "${oci_core_instance.utility.id}"
}

data "oci_core_vnic" "utility_vnic" {
  vnic_id = "${lookup(data.oci_core_vnic_attachments.utility_vnics.vnic_attachments[0], "vnic_id")}"
}

resource "oci_core_volume" "utility" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[0],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "cdh-utility-volume0"
  size_in_gbs         = "${var.utility["size_in_gbs"]}"
}

resource "oci_core_volume_attachment" "utility0" {
  attachment_type = "iscsi"
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.utility.id}"
  volume_id       = "${oci_core_volume.utility.id}"
}

output "Cloudera Manager" { value = "http://${data.oci_core_vnic.utility_vnic.public_ip_address}:7180/cmf/" }
