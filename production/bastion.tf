resource "oci_core_instance" "Bastion" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "CDH Bastion"
  hostname_label      = "CDH-Bastion"
  shape               = "${var.BastionInstanceShape}"
  subnet_id           = "${oci_core_subnet.bastion.*.id[var.AD - 1]}"

  source_details {
    source_type             = "image"
    source_id               = "${var.InstanceImageOCID[var.region]}"
    boot_volume_size_in_gbs = "${var.boot_volume_size}"
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
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1],"name")}"
  instance_id         = "${oci_core_instance.Bastion.id}"
}

data "oci_core_vnic" "bastion_vnic" {
  vnic_id = "${lookup(data.oci_core_vnic_attachments.bastion_vnics.vnic_attachments[0],"vnic_id")}"
}
