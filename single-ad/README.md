# single-ad
Nodes in this deployment are placed in a single availability domain.

| Application             | Worker                           | Bastion          | Utility          | Master           |
|-------------------------|----------------------------------|------------------|------------------|------------------|
| Small Development       | 3xVM.Standard2.16 with 1TB block | 1xVM.Standard2.4 | 1xVM.Standard2.8 |                  |                   
| Recommended Development | 3xVM.Standard2.24 with 1TB block | 1xVM.Standard2.4 | 1xVM.Standard2.8 |                  |
| Small Production        | 5xBM.DenseIO1.36                 | 1xVM.Standard2.4 | 1xVM.Standard2.8 | 2xVM.Standard2.8 |                                
| Recommended Production  | 5xBM.DenseIO2.52                 | 1xVM.Standard2.4 | 1xVM.Standard2.8 | 2xVM.Standard2.8 |                    
