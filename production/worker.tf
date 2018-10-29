resource "oci_core_instance" "worker" {
  count               = "${var.worker["node_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[count.index%var.availability_domains], "name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "worker${count.index}"
  hostname_label      = "worker${count.index}"
  shape               = "${var.worker["shape"]}"
  subnet_id           = "${oci_core_subnet.private.*.id[count.index%var.availability_domains]}"

  source_details {
    source_type = "image"
    source_id   = "${var.images[var.region]}"
  }

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data = "${base64encode(format("%s\n%s\n",
      "#!/usr/bin/env bash",
      file("scripts/shared.sh")
    ))}"
  }
}

resource "oci_core_volume" "worker0" {
  count               = "${var.worker["node_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[count.index%var.availability_domains], "name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "worker${count.index}-volume0"
  size_in_gbs         = "${var.worker["size_in_gbs"]}"
}

resource "oci_core_volume_attachment" "worker0" {
  count           = "${var.worker["node_count"]}"
  attachment_type = "iscsi"
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.worker.*.id[count.index]}"
  volume_id       = "${oci_core_volume.worker0.*.id[count.index]}"
}
