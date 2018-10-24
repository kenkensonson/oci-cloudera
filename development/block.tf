###
### Worker Block Volumes for HDFS - Each stanza set adds a block device for nodecount Workers
###

resource "oci_core_volume" "worker1" {
  count               = "${var.worker["node_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1], "name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "CDH Worker ${format("%01d", count.index+1)} Volume 1"
  size_in_gbs         = "${var.blocksize_in_gbs}"
}

resource "oci_core_volume_attachment" "WorkerAttachment1" {
  count           = "${var.worker["node_count"]}"
  attachment_type = "iscsi"
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.worker.*.id[count.index]}"
  volume_id       = "${oci_core_volume.worker1.*.id[count.index]}"
}
