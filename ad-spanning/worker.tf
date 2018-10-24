resource "oci_core_instance" "WorkerNode" {
  count               = "${var.nodecount}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[count.index%3],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "CDH Worker ${format("%01d", count.index+1)}"
  hostname_label      = "CDH-Worker-${format("%01d", count.index+1)}"
  shape               = "${var.WorkerInstanceShape}"
  subnet_id           = "${oci_core_subnet.private.*.id[count.index%3]}"

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

## HDFS Volumes

resource "oci_core_volume" "Worker1" {
  count = "${var.nodecount}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[count.index%3],"name")}"
  compartment_id = "${var.compartment_ocid}"
  display_name = "CDH Worker ${format("%01d", count.index+1)} Volume 1"
  size_in_gbs = "${var.blocksize_in_gbs}"
}


resource "oci_core_volume_attachment" "Worker1" {
  count = "${var.nodecount}"
  attachment_type = "iscsi"
  compartment_id = "${var.compartment_ocid}"
  instance_id = "${oci_core_instance.WorkerNode.*.id[count.index]}"
  volume_id = "${oci_core_volume.Worker1.*.id[count.index]}"
}

### Worker Block Device 2

resource "oci_core_volume" "Worker2" {
  count = "${var.nodecount}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[count.index%3],"name")}"
  compartment_id = "${var.compartment_ocid}"
  display_name = "CDH Worker ${format("%01d", count.index+1)} Volume 2"
  size_in_gbs = "${var.blocksize_in_gbs}"
}


resource "oci_core_volume_attachment" "Worker2" {
  count = "${var.nodecount}"
  attachment_type = "iscsi"
  compartment_id = "${var.compartment_ocid}"
  instance_id = "${oci_core_instance.WorkerNode.*.id[count.index]}"
  volume_id = "${oci_core_volume.Worker2.*.id[count.index]}"
}

### Worker Block Device 3

resource "oci_core_volume" "Worker3" {
  count = "${var.nodecount}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[count.index%3],"name")}"
  compartment_id = "${var.compartment_ocid}"
  display_name = "CDH Worker ${format("%01d", count.index+1)} Volume 3"
  size_in_gbs = "${var.blocksize_in_gbs}"
}

resource "oci_core_volume_attachment" "Worker3" {
  count = "${var.nodecount}"
  attachment_type = "iscsi"
  compartment_id = "${var.compartment_ocid}"
  instance_id = "${oci_core_instance.WorkerNode.*.id[count.index]}"
  volume_id = "${oci_core_volume.Worker3.*.id[count.index]}"
}

## Block 4

resource "oci_core_volume" "Worker4" {
  count = "${var.nodecount}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[count.index%3],"name")}"
  compartment_id = "${var.compartment_ocid}"
  display_name = "CDH Worker ${format("%01d", count.index+1)} Volume 4"
  size_in_gbs = "${var.blocksize_in_gbs}"
}

resource "oci_core_volume_attachment" "Worker4" {
  count = "${var.nodecount}"
  attachment_type = "iscsi"
  compartment_id = "${var.compartment_ocid}"
  instance_id = "${oci_core_instance.WorkerNode.*.id[count.index]}"
  volume_id = "${oci_core_volume.Worker4.*.id[count.index]}"
}

## Block 5

resource "oci_core_volume" "Worker5" {
  count = "${var.nodecount}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[count.index%3],"name")}"
  compartment_id = "${var.compartment_ocid}"
  display_name = "CDH Worker ${format("%01d", count.index+1)} Volume 5"
  size_in_gbs = "${var.blocksize_in_gbs}"
}

resource "oci_core_volume_attachment" "Worker5" {
  count = "${var.nodecount}"
  attachment_type = "iscsi"
  compartment_id = "${var.compartment_ocid}"
  instance_id = "${oci_core_instance.WorkerNode.*.id[count.index]}"
  volume_id = "${oci_core_volume.Worker5.*.id[count.index]}"
}

## Block 6

resource "oci_core_volume" "Worker6" {
  count = "${var.nodecount}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[count.index%3],"name")}"
  compartment_id = "${var.compartment_ocid}"
  display_name = "CDH Worker ${format("%01d", count.index+1)} Volume 6"
  size_in_gbs = "${var.blocksize_in_gbs}"
}

resource "oci_core_volume_attachment" "Worker6" {
  count = "${var.nodecount}"
  attachment_type = "iscsi"
  compartment_id = "${var.compartment_ocid}"
  instance_id = "${oci_core_instance.WorkerNode.*.id[count.index]}"
  volume_id = "${oci_core_volume.Worker6.*.id[count.index]}"
}
