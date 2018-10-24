# ---------------------------------------------------------------------------------------------------------------------
# Environmental variables
# You probably want to define these as environmental variables.
# Instructions on that are here: https://github.com/cloud-partners/oci-prerequisites
# ---------------------------------------------------------------------------------------------------------------------

variable "compartment_ocid" {}

# Required by the OCI Provider
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}

# Key used to SSH to OCI VMs
variable "ssh_public_key" {}
variable "ssh_private_key" {}

# ---------------------------------------------------------------------------------------------------------------------
# Optional variables
# You can modify these.
# ---------------------------------------------------------------------------------------------------------------------

variable "availability_domain" { default = "2" }

variable "bastion" {
  type = "map"
  default = {
    shape = "VM.Standard2.4"
    node_count = 1
  }
}

variable "utility" {
  type = "map"
  default = {
    shape = "VM.Standard2.8"
    node_count = 1
  }
}

variable "master" {
  type = "map"
  default = {
    shape = "VM.Standard2.8"
    node_count = 0
  }
}

variable "worker" {
  type = "map"
  default = {
    shape = "BM.Standard2.24"
    node_count = 3
    size_in_gbs = "1024"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Constants
# You probably don't need to change these.
# ---------------------------------------------------------------------------------------------------------------------

// See https://docs.us-phoenix-1.oraclecloud.com/images/
// Oracle-provided image "CentOS-7.5-2018.06.22-0"
variable "images" {
  type = "map"

  default = {
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaasdvfvvgzjhqpuwmjbypgovachdgwvcvus5n4p64fajmbassg2pqa"
    us-ashburn-1   = "ocid1.image.oc1.iad.aaaaaaaa5o7kjzy7gqtmu5pxuhnh6yoi3kmzazlk65trhpjx5xg3hfbuqvgq"
    uk-london-1    = "ocid1.image.oc1.uk-london-1.aaaaaaaaa74er3gyrjg3fiesftpc42viplbhp7gdafqzv33kyyx3jrazruta"
    us-phoenix-1   = "ocid1.image.oc1.phx.aaaaaaaapnnv2phiyw7apcgtg6kmn572b2mux56ll6j6mck5xti3aw4bnwrq"
  }
}
