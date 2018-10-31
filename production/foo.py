import math

#Variables
node_count=7
disk_count=5
availability_domains=3

#Nodes
print('i\tinstance\tad')
count=node_count
for i in range(0, count):
    instance=i
    availability_domain=i%availability_domains
    print(str(i) + '\t' + str(instance) + '\t\t' + str(availability_domain))

print('')

#Disks
print('i\tinstance\tvolume\tad')
count=node_count*disk_count
for i in range(0,count):
    instance_id = i%node_count
    availability_domain = i%node_count%availability_domains
    volume_id = math.floor(i/node_count)
    print(str(i) + '\t' + str(instance_id) + '\t\t' + str(int(volume_id)) + '\t' + str(availability_domain))
