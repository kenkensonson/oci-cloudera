resource "oci_core_instance" "worker" {
  count               = "${var.worker["node_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[count.index % var.availability_domains], "name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "worker${count.index}"
  hostname_label      = "worker${count.index}"
  shape               = "${var.worker["shape"]}"
  subnet_id           = "${oci_core_subnet.subnet.*.id[count.index % var.availability_domains]}"

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

resource "oci_core_volume" "worker" {
  count               = "${var.worker["node_count"] * var.worker["disk_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[count.index % var.worker["node_count"] % var.availability_domains], "name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "worker${count.index % var.worker["node_count"]}-volume${floor(count.index / var.worker["node_count"])}"
  size_in_gbs         = "${var.worker["size_in_gbs"]}"
}

resource "oci_core_volume_attachment" "worker" {
  count           = "${var.worker["node_count"] * var.worker["disk_count"]}"
  attachment_type = "iscsi"
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.worker.*.id[count.index % var.worker["node_count"]]}"
  volume_id       = "${oci_core_volume.worker.*.id[count.index]}"
}
