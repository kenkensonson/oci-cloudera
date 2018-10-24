resource "oci_core_instance" "utility" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "CDH-Utility"
  hostname_label      = "CDH-Utility"
  shape               = "${var.master["shape"]}"
  subnet_id           = "${oci_core_subnet.public.*.id[var.AD - 1]}"

  source_details {
    source_type             = "image"
    source_id               = "${var.images[var.region]}"
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

resource "oci_core_instance" "master" {
  count               = "${var.master["node_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1], "name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "CDH-Master-${format("%01d", count.index+1)}"
  hostname_label      = "CDH-Master-${format("%01d", count.index+1)}"
  shape               = "${var.master["shape"]}"
  subnet_id           = "${oci_core_subnet.private.*.id[var.AD - 1]}"

  source_details {
    source_type             = "image"
    source_id               = "${var.images[var.region]}"
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

resource "oci_core_instance" "bastion" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "CDH-Bastion"
  hostname_label      = "CDH-Bastion"
  shape               = "${var.bastion_shape}"
  subnet_id           = "${oci_core_subnet.bastion.*.id[var.AD - 1]}"

  source_details {
    source_type             = "image"
    source_id               = "${var.images[var.region]}"
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

resource "oci_core_instance" "worker" {
  count               = "${var.worker["node_count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "CDH-Worker-${format("%01d", count.index+1)}"
  hostname_label      = "CDH-Worker-${format("%01d", count.index+1)}"
  shape               = "${var.worker["shape"]}"
  subnet_id           = "${oci_core_subnet.private.*.id[var.AD - 1]}"

  source_details {
    source_type             = "image"
    source_id               = "${var.images[var.region]}"
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
