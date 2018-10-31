resource "oci_core_instance" "edge" {
  count               = "${var.edge["node_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[count.index % var.availability_domains], "name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "edge${count.index}"
  hostname_label      = "edge${count.index}"
  shape               = "${var.edge["shape"]}"
  subnet_id           = "${oci_core_subnet.public.*.id[count.index % var.availability_domains]}"

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

resource "oci_core_volume" "edge" {
  count               = "${var.edge["node_count"] * var.edge["disk_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[count.index % var.edge["node_count"] % var.availability_domains], "name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "edge${count.index % var.edge["node_count"]}-volume${floor(count.index / var.edge["node_count"])}"
  size_in_gbs         = "${var.edge["size_in_gbs"]}"
}

resource "oci_core_volume_attachment" "edge" {
  count           = "${var.edge["node_count"] * var.edge["disk_count"]}"
  attachment_type = "iscsi"
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.edge.*.id[count.index % var.edge["node_count"]]}"
  volume_id       = "${oci_core_volume.edge.*.id[count.index]}"
}
