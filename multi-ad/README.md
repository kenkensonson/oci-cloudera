# ad-spanning
This is a variation of the n-node deployment that spans all ADs in a region.  This provides the most highly available solution for running Cloudera EDH on OCI.  It consists of:

* 1 bastion instance
* 1 utility instance
* 2 master nodes
* 3 worker nodes

Storage is on the local NVMe drives as well as six block drives on each worker node.

Nodes are all placed across three availability domains.
