resource "oci_core_instance" "bastion" {
  count               = "${var.bastion["node_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[count.index%var.availability_domains],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "cdh-bastion${count.index}"
  hostname_label      = "cdh-bastion${count.index}"
  shape               = "${var.bastion["shape"]}"
  subnet_id           = "${oci_core_subnet.bastion.*.id[count.index%var.availability_domains]}"

  source_details {
    source_type = "image"
    source_id   = "${var.images[var.region]}"
  }

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data = "${base64encode(format("%s\n%s\n",
      "#!/usr/bin/env bash",
      file("../simple-scripts/bastion.sh")
    ))}"
  }
}

data "oci_core_vnic_attachments" "bastion_vnics" {
  compartment_id      = "${var.compartment_ocid}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[count.index%var.availability_domains],"name")}"
  instance_id         = "${oci_core_instance.bastion.id}"
}

data "oci_core_vnic" "bastion_vnic" {
  vnic_id = "${lookup(data.oci_core_vnic_attachments.bastion_vnics.vnic_attachments[0], "vnic_id")}"
}

output "Bastion IP" { value = "${data.oci_core_vnic.bastion_vnic.public_ip_address}" }
