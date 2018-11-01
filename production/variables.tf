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

# Set to 1 to put everything in on AD or 3 to spread nodes out
variable "availability_domains" { default = 3 }

variable "utility" {
  type = "map"
  default = {
    shape = "VM.Standard2.8"
    node_count = 1
    size_in_gbs = 1024
    disk_count = 0
  }
}

variable "edge" {
  type = "map"
  default = {
    shape = "VM.Standard2.4"
    node_count = 0
    size_in_gbs = 1024
    disk_count = 0
  }
}

variable "master" {
  type = "map"
  default = {
    shape = "VM.Standard2.8"
    node_count = 0
    size_in_gbs = 1024
    disk_count = 1
  }
}

variable "worker" {
  type = "map"
  default = {
    shape = "VM.Standard2.24"
    node_count = 3
    size_in_gbs = 1024
    disk_count = 0
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Constants
# You probably don't need to change these.
# ---------------------------------------------------------------------------------------------------------------------

// https://docs.cloud.oracle.com/iaas/images/image/5cc01498-0a1e-4c68-90c4-31e30120fd5c/
// CentOS-7-2018.10.12-0
variable "images" {
  type = "map"
  default = {
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaav3frw3wod63glppeb2hhh4ao7c6kntgt5jvxy4imiihclgkta7ja"
    us-ashburn-1 = "ocid1.image.oc1.iad.aaaaaaaavujqgegoqyinkxzigumlwydq42vyf6nr3sfl7ram577zzlz2clpa"
    us-phoenix-1 = "ocid1.image.oc1.phx.aaaaaaaazad4ygyhnrwphg7d6eohtop5ny3gri6ab3dkyof7fg75j4jiazta"
    uk-london-1  = "ocid1.image.oc1.uk-london-1.aaaaaaaawhe4tofopwvhg7h6wo3rkt2pmbweykqe2vdb5ztmwewiocd7zo5a"
  }
}
