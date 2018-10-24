resource "oci_core_instance" "sandbox" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[var.availability_domain], "name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "cdh-sandbox"
  hostname_label      = "cdh-sandbox"
  shape               = "VM.Standard2.8"
  subnet_id           = "${oci_core_subnet.public.*.id[var.availability_domain]}"

  source_details {
    source_type = "image"
    source_id   = "${var.images[var.region]}"
  }

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data           = "${base64encode(file("scripts/cloud-init.sh"))}"
  }

  timeouts {
    create = "30m"
  }
}

data "oci_core_vnic_attachments" "sandbox_vnics" {
  compartment_id      = "${var.compartment_ocid}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[var.availability_domain], "name")}"
  instance_id         = "${oci_core_instance.sandbox.id}"
}

data "oci_core_vnic" "sandbox_vnic" {
  vnic_id = "${lookup(data.oci_core_vnic_attachments.sandbox_vnics.vnic_attachments[0], "vnic_id")}"
}
