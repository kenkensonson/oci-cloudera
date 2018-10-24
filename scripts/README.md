# scripts
All scripts in this location are referenced for deployment automation as part of Development, Production, and N-Node templates.

* start.sh is the first script invoked by Terraform in remote-execution. It calls the bastion script in a Linux screen session as root.
* bastion.sh is the primary script which drives discovery and deployment tasks. It is invoked by start.sh and runs on the bastion host.
* boot.sh is invoked by cloud-init on each instance creation via Terraform.  It contains steps which perform initial bootstrapping of the instance prior to provisioning.
* cms_install.sh is the primary script for installing Cloudera Manager.
* install-postgresql.sh installs Postgres on the utility node for use with Cloudera Manager metadata.
* node_prep.sh is the top level node bootstrapping script, this is called on each node in parallel and executes the following scripts:
- iscsi.sh detects and sets up block storage via iscsi.
- disk_setup.sh is used for disk formatting to use with HDFS.
- tune.sh is used for OS performance tuning.
* startup.sh drives the Cloudera EDH install after Cloudera Manager has been installed.  It invokes the following script, and should be customized prior to deployment with user details section and password for Cloudera Manager.
* cmx.py is a Python script drives all cluster deployment automation via the Cloudera Manager Python API.
