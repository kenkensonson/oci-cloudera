resource "oci_core_instance" "utility" {
  count               = "${var.utility["node_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[count.index%3],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "cdh-utility-${format("%01d", count.index+1)}"
  hostname_label      = "cdh-utility-${format("%01d", count.index+1)}"
  shape               = "${var.utility["shape"]}"
  subnet_id           = "${oci_core_subnet.public.*.id[count.index%3]}"
  
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

data "oci_core_vnic_attachments" "utility_vnics" {
  compartment_id      = "${var.compartment_ocid}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.availability_domains.availability_domains[count.index%3],"name")}"
  instance_id         = "${oci_core_instance.utility.id}"
}

data "oci_core_vnic" "utility_vnic" {
  vnic_id = "${lookup(data.oci_core_vnic_attachments.utility_vnics.vnic_attachments[0], "vnic_id")}"
}
