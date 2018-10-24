resource "oci_core_instance" "worker" {
  count               = "${var.worker["node_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.availability_domain], "name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "cdh-worker-${format("%01d", count.index+1)}"
  hostname_label      = "cdh-worker-${format("%01d", count.index+1)}"
  shape               = "${var.worker["shape"]}"
  subnet_id           = "${oci_core_subnet.private.*.id[var.availability_domain]}"

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

resource "oci_core_volume" "worker1" {
  count               = "${var.worker["node_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.availability_domain], "name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "cdh-worker${format("%01d", count.index+1)}-volume1"
  size_in_gbs         = "${var.worker["size_in_gbs"]}"
}

resource "oci_core_volume_attachment" "worker1" {
  count           = "${var.worker["node_count"]}"
  attachment_type = "iscsi"
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.worker.*.id[count.index]}"
  volume_id       = "${oci_core_volume.worker1.*.id[count.index]}"
}
