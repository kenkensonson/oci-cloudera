resource "oci_core_instance" "master" {
  count               = "${var.master["node_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[var.availability_domain], "name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "cdh-master-${format("%01d", count.index)}"
  hostname_label      = "cdh-master-${format("%01d", count.index)}"
  shape               = "${var.master["shape"]}"
  subnet_id           = "${oci_core_subnet.private.*.id[var.availability_domain]}"

  source_details {
    source_type             = "image"
    source_id               = "${var.images[var.region]}"
  }

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data           = "${base64encode(file("../scripts/boot.sh"))}"
  }

  timeouts {
    create = "30m"
  }
}

resource "oci_core_volume" "master" {
  count               = "${var.master["node_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[var.availability_domain], "name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "cdh-master${format("%01d", count.index+1)}"
  size_in_gbs         = "${var.master["size_in_gbs"]}"
}

resource "oci_core_volume_attachment" "master" {
  count           = "${var.master["node_count"]}"
  attachment_type = "iscsi"
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.master.*.id[count.index]}"
  volume_id       = "${oci_core_volume.master.*.id[count.index]}"
}
