resource "oci_core_instance" "utility" {
  count               = "${var.utility["node_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[count.index%var.availability_domains],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "cdh-utility${count.index}"
  hostname_label      = "cdh-utility${count.index}"
  shape               = "${var.utility["shape"]}"
  subnet_id           = "${oci_core_subnet.public.*.id[count.index%var.availability_domains]}"

  source_details {
    source_type = "image"
    source_id   = "${var.images[var.region]}"
  }

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data = "${base64encode(format("%s\n%s\n%s\n",
      "#!/usr/bin/env bash",
      file("../scripts/shared.sh")
      file("../scripts/utility.sh")
    ))}"
  }
}

data "oci_core_vnic_attachments" "utility_vnics" {
  compartment_id      = "${var.compartment_ocid}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[count.index%var.availability_domains],"name")}"
  instance_id         = "${oci_core_instance.utility.id}"
}

data "oci_core_vnic" "utility_vnic" {
  vnic_id = "${lookup(data.oci_core_vnic_attachments.utility_vnics.vnic_attachments[0], "vnic_id")}"
}

resource "oci_core_volume" "utility0" {
  count               = "${var.utility["node_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[count.index%var.availability_domains],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "cdh-utility${count.index}-volume0"
  size_in_gbs         = "${var.utility["size_in_gbs"]}"
}

resource "oci_core_volume_attachment" "utility0" {
  count           = "${var.utility["node_count"]}"
  attachment_type = "iscsi"
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.utility.*.id[count.index]}"
  volume_id       = "${oci_core_volume.utility0.*.id[count.index]}"
}

output "Cloudera Manager Login Available after ~15m" { value = "http://${data.oci_core_vnic.utility_vnic.public_ip_address}:7180/cmf/" }
