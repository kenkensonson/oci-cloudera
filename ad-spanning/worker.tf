resource "oci_core_instance" "worker" {
  count               = "${var.worker["node_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[var.availability_domain], "name")}"
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
  count = "${var.worker["node_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[count.index%3],"name")}"
  compartment_id = "${var.compartment_ocid}"
  display_name = "cdh-worker${format("%01d", count.index+1)}-volume1"
  size_in_gbs = "${var.worker["size_in_gbs"]}"
}

resource "oci_core_volume_attachment" "worker1" {
  count = "${var.worker["node_count"]}"
  attachment_type = "iscsi"
  compartment_id = "${var.compartment_ocid}"
  instance_id = "${oci_core_instance.worker.*.id[count.index]}"
  volume_id = "${oci_core_volume.worker1.*.id[count.index]}"
}

resource "oci_core_volume" "worker2" {
  count = "${var.worker["node_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[count.index%3],"name")}"
  compartment_id = "${var.compartment_ocid}"
  display_name = "cdh-worker${format("%01d", count.index+1)}-volume2"
  size_in_gbs = "${var.worker["size_in_gbs"]}"
}

resource "oci_core_volume_attachment" "worker2" {
  count = "${var.worker["node_count"]}"
  attachment_type = "iscsi"
  compartment_id = "${var.compartment_ocid}"
  instance_id = "${oci_core_instance.worker.*.id[count.index]}"
  volume_id = "${oci_core_volume.worker2.*.id[count.index]}"
}

resource "oci_core_volume" "worker3" {
  count = "${var.worker["node_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[count.index%3],"name")}"
  compartment_id = "${var.compartment_ocid}"
  display_name = "cdh-worker${format("%01d", count.index+1)}-volume3"
  size_in_gbs = "${var.worker["size_in_gbs"]}"
}

resource "oci_core_volume_attachment" "worker3" {
  count = "${var.worker["node_count"]}"
  attachment_type = "iscsi"
  compartment_id = "${var.compartment_ocid}"
  instance_id = "${oci_core_instance.worker.*.id[count.index]}"
  volume_id = "${oci_core_volume.worker3.*.id[count.index]}"
}

resource "oci_core_volume" "worker4" {
  count = "${var.worker["node_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[count.index%3],"name")}"
  compartment_id = "${var.compartment_ocid}"
  display_name = "cdh-worker${format("%01d", count.index+1)}-volume4"
  size_in_gbs = "${var.worker["size_in_gbs"]}"
}

resource "oci_core_volume_attachment" "worker4" {
  count = "${var.worker["node_count"]}"
  attachment_type = "iscsi"
  compartment_id = "${var.compartment_ocid}"
  instance_id = "${oci_core_instance.worker.*.id[count.index]}"
  volume_id = "${oci_core_volume.worker4.*.id[count.index]}"
}

resource "oci_core_volume" "worker5" {
  count = "${var.worker["node_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[count.index%3],"name")}"
  compartment_id = "${var.compartment_ocid}"
  display_name = "cdh-worker${format("%01d", count.index+1)}-volume5"
  size_in_gbs = "${var.worker["size_in_gbs"]}"
}

resource "oci_core_volume_attachment" "worker5" {
  count = "${var.worker["node_count"]}"
  attachment_type = "iscsi"
  compartment_id = "${var.compartment_ocid}"
  instance_id = "${oci_core_instance.worker.*.id[count.index]}"
  volume_id = "${oci_core_volume.worker5.*.id[count.index]}"
}

resource "oci_core_volume" "worker6" {
  count = "${var.worker["node_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[count.index%3],"name")}"
  compartment_id = "${var.compartment_ocid}"
  display_name = "cdh-worker${format("%01d", count.index+1)}-volume6"
  size_in_gbs = "${var.worker["size_in_gbs"]}"
}

resource "oci_core_volume_attachment" "worker6" {
  count = "${var.worker["node_count"]}"
  attachment_type = "iscsi"
  compartment_id = "${var.compartment_ocid}"
  instance_id = "${oci_core_instance.worker.*.id[count.index]}"
  volume_id = "${oci_core_volume.worker6.*.id[count.index]}"
}
