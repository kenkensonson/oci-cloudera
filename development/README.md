# development
This deployment is for small implementations.  It consists of:

* 1 bastion instance
* 1 utility instance
* 3 worker nodes

Storage is on 1024GB block volumes attached to the worker nodes.  

Nodes are all placed in a single availability domain.

|             | Worker                                 | Bastion        | Utility        |
|-------------|----------------------------------------|----------------|----------------|
| Minimum     | VM.Standard2.16 with 1TB Block Storage | VM.Standard2.4 | VM.Standard2.8 |                   
| Recommended | VM.Standard2.24 with 1TB Block Storage | VM.Standard2.4 | VM.Standard2.8 |
