resource "oci_core_instance" "Bastion" {
  count               = "${var.BastionNodeCount}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[count.index%3],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "CDH Bastion${count.index+1}"
  hostname_label      = "CDH-Bastion${count.index+1}"
  shape               = "${var.BastionInstanceShape}"
  subnet_id           = "${oci_core_subnet.bastion.*.id[count.index%3]}"

  source_details {
    source_type             = "image"
    source_id               = "${var.InstanceImageOCID[var.region]}"
    boot_volume_size_in_gbs = "${var.boot_volume_size}"
  }

  create_vnic_details {
    subnet_id              = "${oci_core_subnet.bastion.*.id[count.index%3]}"
    skip_source_dest_check = true
  }

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data           = "${base64encode(file("scripts/bastion_boot.sh"))}"
  }

  timeouts {
    create = "30m"
  }
}

data "oci_core_vnic_attachments" "bastion_vnics" {
  compartment_id      = "${var.compartment_ocid}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  instance_id         = "${oci_core_instance.Bastion.*.id[0]}"
}

resource "oci_core_private_ip" "bastion_private_ip" {
  vnic_id      = "${lookup(data.oci_core_vnic_attachments.bastion_vnics.vnic_attachments[0],"vnic_id")}"
  display_name = "bastion_private_ip"
}

data "oci_core_vnic" "bastion_vnic" {
  vnic_id = "${lookup(data.oci_core_vnic_attachments.bastion_vnics.vnic_attachments[0],"vnic_id")}"
}
