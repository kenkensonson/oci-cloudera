# production
This is the most powerful preconfigured option.  It provides high density, high performance and high availability.  It is an appropriate entry point for scaling up a production big data practice.  It consists of:

* 1 bastion instance
* 1 utility instance
* 2 master nodes
* 5 worker nodes

Storage is on the local NVMe drives on the worker nodes.  

Nodes are all placed in a single availability domain.

|             | Worker         | Bastion        | Utility        | Master         |
|-------------|----------------|----------------|----------------|----------------|
| Minimum     | BM.DenseIO1.36 | VM.Standard2.4 | VM.Standard1.8 | VM.Standard2.8 |                                
| Recommended | BM.DenseIO2.52 | VM.Standard2.4 | VM.Standard2.8 | VM.Standard2.8 |                    
