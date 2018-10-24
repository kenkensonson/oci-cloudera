resource "oci_core_instance" "bastion" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.availability_domain], "name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "cdh-bastion"
  hostname_label      = "cdh-bastion"
  shape               = "VM.Standard2.4"
  subnet_id           = "${oci_core_subnet.bastion.*.id[var.availability_domain]}"

  source_details {
    source_type = "image"
    source_id   = "${var.images[var.region]}"
  }

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data           = "${base64encode(file("../scripts/boot.sh"))}"
  }

  timeouts {
    create = "30m"
  }
}

data "oci_core_vnic_attachments" "bastion_vnics" {
  compartment_id      = "${var.compartment_ocid}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.availability_domain], "name")}"
  instance_id         = "${oci_core_instance.bastion.id}"
}

data "oci_core_vnic" "bastion_vnic" {
  vnic_id = "${lookup(data.oci_core_vnic_attachments.bastion_vnics.vnic_attachments[0], "vnic_id")}"
}
