resource "oci_core_instance" "master" {
  count               = "${var.master["node_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[count.index%var.availability_domains],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "cdh-master${count.index}"
  hostname_label      = "cdh-master${count.index}"
  shape               = "${var.master["shape"]}"
  subnet_id           = "${oci_core_subnet.private.*.id[count.index%var.availability_domains]}"

  source_details {
    source_type = "image"
    source_id   = "${var.images[var.region]}"
  }

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data = "${base64encode(format("%s\n%s\n",
      "#!/usr/bin/env bash",
      file("../scripts/master.sh")
    ))}"
  }
}

resource "oci_core_volume" "master0" {
  count               = "${var.master["node_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[count.index%var.availability_domains],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "cdh-master${count.index}-volume0"
  size_in_gbs         = "${var.master["size_in_gbs"]}"
}

resource "oci_core_volume_attachment" "master0" {
  count           = "${var.master["node_count"]}"
  attachment_type = "iscsi"
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.master.*.id[count.index]}"
  volume_id       = "${oci_core_volume.master0.*.id[count.index]}"
}
