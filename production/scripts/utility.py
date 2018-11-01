import argparse

import socket
import re
import urllib
import urllib2
import hashlib
import os
import sys
import random
from time import sleep
from cm_api.api_client import ApiResource, ApiException
from cm_api.endpoints.hosts import *
from cm_api.endpoints.services import ApiServiceSetupInfo, ApiService

def setupArguments():
    parser = argparse.ArgumentParser(description='Setup a Cloudera Cluster', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    required = parser.add_argument_group('Required named arguments')
    required.add_argument('--host_names', required=True, type=str, help='Node list, separate with commas: host1,host2,...,host(n)')
    required.add_argument('--ssh_private_key_filename', required=True, type=str, help='The private key to authenticate with the hosts')
    required.add_argument('--vm_size', required=True, type=str, help='VM Size for CPU and Memory Setup')
    required.add_argument('--disk_count', required=True, type=int, help='Number of Data Disks on Each Node')
    parser.add_argument('--cluster_name', type=str, default='cluster')
    parser.add_argument('--ssh_root_user', type=str, default='opc')
    parser.add_argument('--cm_server', type=str, default='localhost')
    return parser

def wait_for_cm_to_start():
    retry_count = 5
    while retry_count > 0:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        if not s.connect_ex((socket.gethostbyname(value), 7180)) == 0:
            print "Cloudera Manager Server is not started on %s " % value
            s.close()
            sleep(60)
        else:
            break
        retry_count -= 1
    if retry_count == 0:
        print "Couldn't connect to Cloudera Manager after 5 minutes, exiting"
        exit(1)

def init_cluster(api, options):
    print "> Initialize Cluster"
    cm = api.get_cloudera_manager()
    cm.update_config({"REMOTE_PARCEL_REPO_URLS": "http://archive.cloudera.com/cdh6/parcels/{latest_supported}", "PHONE_HOME": True, "PARCEL_DISTRIBUTE_RATE_LIMIT_KBS_PER_SECOND": "1024000"})

    if cmx.cluster_name in [x.name for x in api.get_all_clusters()]:
        print "Cluster name: '%s' already exists" % options.cluster_name
    else:
        print "Creating cluster name '%s'" % cmx.cluster_name
        api.create_cluster(name=options.cluster_name, version="CDH6")


def add_hosts_to_cluster(api, options):
    print "> Add hosts to Cluster: %s" % options.cluster_name
    cluster = api.get_cluster(options.cluster_name)
    cm = api.get_cloudera_manager()
    cmd = cm.host_install(user_name=options.ssh_root_user, host_names=options.host_names, private_key=options.ssh_private_key_filename)

    print "Installing agents - [ http://localhost:7180/cmf/command/%s/details ]" % (cmd.id)
    while cmd.success == None:
        sleep(20)
        cmd = cmd.fetch()
        print "Waiting for install agents to finish..."

    if cmd.success != True:
        print "cm.host_install failed: " + cmd.resultMessage
        exit(1)

    hosts = []
    for host in api.get_all_hosts():
        print "Adding {'ip': '%s', 'hostname': '%s', 'hostId': '%s'}" % (host.ipAddress, host.hostname, host.hostId)
        hosts.append(host.hostId)

    print "Adding hosts to cluster..."
    print hosts
    cluster.add_hosts(hosts)


def getParameterValue(vmsize, parameter):
    log("vmsize: " + vmsize + ", parameter:" + parameter)
    switcher = {
        "BM.DenseIO2.52:yarn_nodemanager_resource_cpu_vcores": "208",
        "BM.DenseIO2.52:yarn_nodemanager_resource_memory_mb": "786432",
        "BM.DenseIO2.52:impalad_memory_limit": "274877906944",
        "BM.DenseIO2.52:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2080m -Xmx2080m",
        "BM.DenseIO2.52:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2080m -Xmx2080m",
        "BM.DenseIO2.52:dfs_replication": "3",
        "BM.DenseIO1.36:yarn_nodemanager_resource_cpu_vcores": "128",
        "BM.DenseIO1.36:yarn_nodemanager_resource_memory_mb": "524288",
        "BM.DenseIO1.36:impalad_memory_limit": "274877906944",
        "BM.DenseIO1.36:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms1896m -Xmx1896m",
        "BM.DenseIO1.36:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms1896m -Xmx1896m",
        "BM.DenseIO1.36:dfs_replication": "3",
        "BM.Standard2.52:yarn_nodemanager_resource_cpu_vcores": "208",
        "BM.Standard2.52:yarn_nodemanager_resource_memory_mb": "786432",
        "BM.Standard2.52:impalad_memory_limit": "274877906944",
        "BM.Standard2.52:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2080m -Xmx2080m",
        "BM.Standard2.52:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2080m -Xmx2080m",
        "BM.Standard2.52:dfs_replication": "1",
        "BM.Standard1.36:yarn_nodemanager_resource_cpu_vcores": "128",
        "BM.Standard1.36:yarn_nodemanager_resource_memory_mb": "242688",
        "BM.Standard1.36:impalad_memory_limit": "122857142857",
        "BM.Standard1.36:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms1896m -Xmx1896m",
        "BM.Standard1.36:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms1896m -Xmx1896m",
        "BM.Standard1.36:dfs_replication": "1",
        "VM.Standard2.24:yarn_nodemanager_resource_cpu_vcores": "80",
        "VM.Standard2.24:yarn_nodemanager_resource_memory_mb": "308224",
        "VM.Standard2.24:impalad_memory_limit": "122857142857",
        "VM.Standard2.24:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms3853m -Xmx3853m",
        "VM.Standard2.24:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms3853m -Xmx3853m",
        "VM.Standard2.24:dfs_replication": "1",
        "VM.Standard2.16:yarn_nodemanager_resource_cpu_vcores": "48",
        "VM.Standard2.16:yarn_nodemanager_resource_memory_mb": "237568",
        "VM.Standard2.16:impalad_memory_limit": "42949672960",
        "VM.Standard2.16:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms1984m -Xmx1984m",
        "VM.Standard2.16:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms1984m -Xmx1984m",
        "VM.Standard2.16:dfs_replication": "1",
        "VM.Standard1.16:yarn_nodemanager_resource_cpu_vcores": "48",
        "VM.Standard1.16:yarn_nodemanager_resource_memory_mb": "95232",
        "VM.Standard1.16:impalad_memory_limit": "42949672960",
        "VM.Standard1.16:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms1984m -Xmx1984m",
        "VM.Standard1.16:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms1984m -Xmx1984m",
        "VM.Standard1.16:dfs_replication": "1",
        "VM.Standard2.8:yarn_nodemanager_resource_cpu_vcores": "16",
        "VM.Standard2.8:yarn_nodemanager_resource_memory_mb": "114688",
        "VM.Standard2.8:impalad_memory_limit": "21500000000",
        "VM.Standard2.8:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2368m -Xmx2368m",
        "VM.Standard2.8:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2368m -Xmx2368m",
        "VM.Standard2.8:dfs_replication": "1",
        "VM.DenseIO2.8:yarn_nodemanager_resource_cpu_vcores": "16",
        "VM.DenseIO2.8:yarn_nodemanager_resource_memory_mb": "114688",
        "VM.DenseIO2.8:impalad_memory_limit": "21500000000",
        "VM.DenseIO2.8:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2368m -Xmx2368m",
        "VM.DenseIO2.8:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2368m -Xmx2368m",
        "VM.DenseIO2.8:dfs_replication": "3",
        "VM.DenseIO1.8:yarn_nodemanager_resource_cpu_vcores": "16",
        "VM.DenseIO1.8:yarn_nodemanager_resource_memory_mb": "114688",
        "VM.DenseIO1.8:impalad_memory_limit": "21500000000",
        "VM.DenseIO1.8:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2368m -Xmx2368m",
        "VM.DenseIO1.8:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2368m -Xmx2368m",
        "VM.DenseIO1.8:dfs_replication": "3",
        "VM.Standard1.8:yarn_nodemanager_resource_cpu_vcores": "16",
        "VM.Standard1.8:yarn_nodemanager_resource_memory_mb": "37888",
        "VM.Standard1.8:impalad_memory_limit": "21500000000",
        "VM.Standard1.8:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2368m -Xmx2368m",
        "VM.Standard1.8:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2368m -Xmx2368m",
        "VM.Standard1.8:dfs_replication": "1",
    }
    return switcher.get(vmsize + ":" + parameter)


def host_rack():
    print "> Add host to rack"
    api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
    cluster = api.get_cluster(cmx.cluster_name)
    hosts = []
    for h in api.get_all_hosts():
        if "private1" in h.hostname:
            h.set_rack_id("/rack1")
            print "Adding '%s' to /rack1" % (h.hostname)
        elif "private2" in h.hostname:
            h.set_rack_id("/rack2")
            print "Adding '%s' to /rack2" % (h.hostname)
        elif "private3" in h.hostname:
            h.set_rack_id("/rack3")
            print "Adding '%s' to /rack3" % (h.hostname)
        else:
            h.set_rack_id("/default")
            print "Adding '%s' to /default" % (h.hostname)
        hosts.append(h)

    hosts.append(hosts)


def deploy_parcel(parcel_product, parcel_version):
    api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
    cluster = api.get_cluster(cmx.cluster_name)
    parcel = cluster.get_parcel(parcel_product, parcel_version)
    if parcel.stage != 'ACTIVATED':
        print "> Deploying parcel: [ %s-%s ]" % (
            parcel_product, parcel_version)
        parcel.start_download()
        # unlike other commands, check progress by looking at parcel stage and status
        while True:
            parcel = cluster.get_parcel(parcel_product, parcel_version)
            if parcel.stage == 'DISTRIBUTED' or parcel.stage == 'DOWNLOADED' or parcel.stage == 'ACTIVATED':
                break
            msg = " [%s: %s / %s]" % (parcel.stage, parcel.state.progress, parcel.state.totalProgress)
            sys.stdout.write(msg + " " * (78 - len(msg)) + "\r")
            sys.stdout.flush()

        print ""
        print "1. Parcel Stage: %s" % parcel.stage
        parcel.start_distribution()

        while True:
            parcel = cluster.get_parcel(parcel_product, parcel_version)
            if parcel.stage == 'DISTRIBUTED' or parcel.stage == 'ACTIVATED':
                break
            msg = " [%s: %s / %s]" % (parcel.stage, parcel.state.progress, parcel.state.totalProgress)
            sys.stdout.write(msg + " " * (78 - len(msg)) + "\r")
            sys.stdout.flush()

        print "2. Parcel Stage: %s" % parcel.stage
        if parcel.stage == 'DISTRIBUTED':
            parcel.activate()

        while True:
            parcel = cluster.get_parcel(parcel_product, parcel_version)
            if parcel.stage != 'ACTIVATED':
                msg = " [%s: %s / %s]" % (parcel.stage, parcel.state.progress, parcel.state.totalProgress)
                sys.stdout.write(msg + " " * (78 - len(msg)) + "\r")
                sys.stdout.flush()
            else:
                print "3. Parcel Stage: %s" % parcel.stage
                break


def setup_zookeeper(HA):
    api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
    cluster = api.get_cluster(cmx.cluster_name)
    service_type = "ZOOKEEPER"
    if cdh.get_service_type(service_type) is None:
        print "> %s" % service_type
        service_name = "zookeeper"
        print "Create %s service" % service_name
        cluster.create_service(service_name, service_type)
        service = cluster.get_service(service_name)

        hosts = management.get_hosts()
        cmhost = management.get_cmhost()

        service.update_config({"zookeeper_datadir_autocreate": True})

        # Ensure zookeeper has access to folder
        setZookeeperOwnerDir(HA)

        # Role Config Group equivalent to Service Default Group
        for rcg in [x for x in service.get_all_role_config_groups()]:
            if rcg.roleType == "SERVER":
                rcg.update_config({"maxClientCnxns": "1024", "dataLogDir": LOG_DIR + "/zookeeper", "dataDir": LOG_DIR + "/zookeeper", "zk_server_log_dir": LOG_DIR + "/zookeeper"})
                # Pick 3 hosts and deploy Zookeeper Server role for Zookeeper HA
                # mingrui change install on primary, secondary, and CM
                if HA:
                    print cmhost
                    print [x for x in hosts if x.id == 0][0]
                    print [x for x in hosts if x.id == 1][0]
                    cdh.create_service_role(service, rcg.roleType, cmhost)
                    cdh.create_service_role(service, rcg.roleType, [x for x in hosts if x.id == 0][0])
                    cdh.create_service_role(service, rcg.roleType, [x for x in hosts if x.id == 1][0])
                # No HA, using POC setup, all service in one master node aka the cm host
                else:
                    cdh.create_service_role(service, rcg.roleType, cmhost)

        # init_zookeeper not required as the API performs this when adding Zookeeper
        # check.status_for_command("Waiting for ZooKeeper Service to initialize", service.init_zookeeper())
        check.status_for_command("Starting ZooKeeper Service", service.start())


def setup_hdfs(HA):
    api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
    cluster = api.get_cluster(cmx.cluster_name)
    service_type = "HDFS"
    if cdh.get_service_type(service_type) is None:
        print "> %s" % service_type
        service_name = "hdfs"
        print "Create %s service" % service_name
        cluster.create_service(service_name, service_type)
        service = cluster.get_service(service_name)
        hosts = management.get_hosts()

        # Service-Wide
        service_config = cdh.dependencies_for(service)
        service_config.update({"dfs_replication": getParameterValue(cmx.vmsize, "dfs_replication"), "dfs_block_local_path_access_user": "impala,hbase,mapred,spark"})
        service.update_config(service_config)

        # Get Disk Information - assume that all disk configuration is heterogeneous throughout the cluster

        default_name_dir_list = ""
        default_snn_dir_list = ""
        default_data_dir_list = ""

        dfs_name_dir_list = default_name_dir_list
        dfs_snn_dir_list = default_snn_dir_list
        dfs_data_dir_list = default_data_dir_list

        data_tiering_file = os.path.isfile("/home/opc/hdfs_data_tiering.txt")
        if data_tiering_file is True:
            with open("/home/opc/hdfs_data_tiering.txt") as d:
                dfs_data_dir_list = d.readline().strip()
        else:
            # Normal dfs.data.dir setup
            for x in range(int(diskcount)):
                if x is 0:
                    dfs_data_dir_list += "/data%d/dfs/dn" % (x)
                else:
                    dfs_data_dir_list += ",/data%d/dfs/dn" % (x)

        dfs_name_dir_list += ",/data/dfs/nn"
        dfs_snn_dir_list += ",/data/dfs/snn"

        # No HA, using POC setup, all service in one master node aka the cm host
        if not HA:
            nn_host_id = management.get_cmhost()
            snn_host_id = management.get_cmhost()
        else:
            nn_host_id = [host for host in hosts if host.id == 0][0]
            snn_host_id = [host for host in hosts if host.id == 1][0]

        # Role Config Group equivalent to Service Default Group
        for rcg in [x for x in service.get_all_role_config_groups()]:
            if rcg.roleType == "NAMENODE":
                # hdfs-NAMENODE - Default Group
                rcg.update_config({"dfs_name_dir_list": dfs_name_dir_list,
                                   "namenode_java_heapsize": "4196000000",
                                   "dfs_namenode_handler_count": "70",
                                   "dfs_namenode_service_handler_count": "70",
                                   "dfs_namenode_servicerpc_address": "8022",
                                   "namenode_log_dir": LOG_DIR + "/hadoop-hdfs"})
                cdh.create_service_role(service, rcg.roleType, nn_host_id)
            if rcg.roleType == "SECONDARYNAMENODE":
                # hdfs-SECONDARYNAMENODE - Default Group
                rcg.update_config({"fs_checkpoint_dir_list": dfs_snn_dir_list,
                                   "secondary_namenode_java_heapsize": "4196000000",
                                   "secondarynamenode_log_dir": LOG_DIR + "/hadoop-hdfs"})
                # chose a server that it's not NN, easier to enable HDFS-HA later
                cdh.create_service_role(service, rcg.roleType, snn_host_id)

            if rcg.roleType == "DATANODE":
                # hdfs-DATANODE - Default Group
                rcg.update_config({"datanode_java_heapsize": "351272960",
                                   "dfs_data_dir_list": dfs_data_dir_list,
                                   "dfs_datanode_data_dir_perm": "755",
                                   "dfs_datanode_du_reserved": "3508717158",
                                   "dfs_datanode_failed_volumes_tolerated": "0",
                                   "dfs_datanode_max_locked_memory": "1257242624",
                                   "dfs_datanode_max_xcievers": "16384",
                                   "datanode_log_dir": LOG_DIR + "/hadoop-hdfs"})
            if rcg.roleType == "FAILOVERCONTROLLER":
                rcg.update_config(
                    {"failover_controller_log_dir": LOG_DIR + "/hadoop-hdfs"})
            if rcg.roleType == "HTTPFS":
                rcg.update_config(
                    {"httpfs_log_dir": LOG_DIR + "/hadoop-httpfs"})

            if rcg.roleType == "GATEWAY":
                # hdfs-GATEWAY - Default Group
                rcg.update_config({"dfs_client_use_trash": True})

    # print nn_host_id.hostId
    # print snn_host_id.hostId
    for role_type in ['DATANODE']:
        for host in management.get_hosts(include_cm_host=False):
            if host.hostId != nn_host_id.hostId:
                if host.hostId != snn_host_id.hostId:
                    cdh.create_service_role(service, role_type, host)

        for role_type in ['GATEWAY']:
            for host in management.get_hosts(include_cm_host=(role_type == 'GATEWAY')):
                cdh.create_service_role(service, role_type, host)

        nn_role_type = service.get_roles_by_type("NAMENODE")[0]
        commands = service.format_hdfs(nn_role_type.name)
        for cmd in commands:
            check.status_for_command("Format NameNode", cmd)

        check.status_for_command("Starting HDFS.", service.start())
        check.status_for_command(
            "Creating HDFS /tmp directory", service.create_hdfs_tmp())

    # Additional HA setting for yarn
    if HA:
        setup_hdfs_ha()


def setup_hbase():
    api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
    cluster = api.get_cluster(cmx.cluster_name)
    service_type = "HBASE"
    if cdh.get_service_type(service_type) is None:
        print "> %s" % service_type
        service_name = "hbase"
        print "Create %s service" % service_name
        cluster.create_service(service_name, service_type)
        service = cluster.get_service(service_name)
        hosts = management.get_hosts()

        # Service-Wide
        service.update_config(cdh.dependencies_for(service))

        master_host_id = [host for host in hosts if host.id == 0][0]
        backup_master_host_id = [host for host in hosts if host.id == 1][0]
        cmhost = management.get_cmhost()

        for rcg in [x for x in service.get_all_role_config_groups()]:
            if rcg.roleType == "MASTER":
                cdh.create_service_role(service, rcg.roleType, master_host_id)
                cdh.create_service_role(
                    service, rcg.roleType, backup_master_host_id)
                cdh.create_service_role(service, rcg.roleType, cmhost)

            if rcg.roleType == "REGIONSERVER":
                for host in management.get_hosts(include_cm_host=False):
                    if host.hostId != master_host_id.hostId:
                        if host.hostId != backup_master_host_id.hostId:
                            cdh.create_service_role(
                                service, rcg.roleType, host)

        for role_type in ['GATEWAY']:
            for host in management.get_hosts(include_cm_host=(role_type == 'GATEWAY')):
                cdh.create_service_role(service, role_type, host)

        check.status_for_command("Creating HBase root directory", service.create_hbase_root())
        check.status_for_command("Starting HBase Service", service.start())


def setup_solr():
    api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
    cluster = api.get_cluster(cmx.cluster_name)
    service_type = "SOLR"
    if cdh.get_service_type(service_type) is None:
        print "> %s" % service_type
        service_name = "solr"
        print "Create %s service" % service_name
        cluster.create_service(service_name, service_type)
        service = cluster.get_service(service_name)
        hosts = management.get_hosts()

        # Service-Wide
        service.update_config(cdh.dependencies_for(service))

        # Role Config Group equivalent to Service Default Group
        for rcg in [x for x in service.get_all_role_config_groups()]:
            if rcg.roleType == "SOLR_SERVER":
                cdh.create_service_role(service, rcg.roleType, [
                                        x for x in hosts if x.id == 0][0])
            if rcg.roleType == "GATEWAY":
                for host in management.get_hosts(include_cm_host=True):
                    cdh.create_service_role(service, rcg.roleType, host)

        check.status_for_command("Initializing Solr in ZooKeeper", service.init_solr())
        check.status_for_command("Creating HDFS home directory for Solr", service.create_solr_hdfs_home_dir())


def setup_ks_indexer():
    api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
    cluster = api.get_cluster(cmx.cluster_name)
    service_type = "KS_INDEXER"
    if cdh.get_service_type(service_type) is None:
        print "> %s" % service_type
        service_name = "ks_indexer"
        print "Create %s service" % service_name
        cluster.create_service(service_name, service_type)
        service = cluster.get_service(service_name)
        hosts = management.get_hosts()

        # Service-Wide
        service.update_config(cdh.dependencies_for(service))

        # Pick 1 host to deploy Lily HBase Indexer Default Group
        cdh.create_service_role(service, "HBASE_INDEXER", random.choice(hosts))

        # HBase Service-Wide configuration
        hbase = cdh.get_service_type('HBASE')
        hbase.stop()
        hbase.update_config({"hbase_enable_indexing": True,
                             "hbase_enable_replication": True})
        hbase.start()


def setup_spark_on_yarn():
    api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
    cluster = api.get_cluster(cmx.cluster_name)
    service_type = "SPARK_ON_YARN"
    if cdh.get_service_type(service_type) is None:
        print "> %s" % service_type
        service_name = "spark_on_yarn"
        print "Create %s service" % service_name
        cluster.create_service(service_name, service_type)
        service = cluster.get_service(service_name)
        hosts = management.get_hosts()

        # Service-Wide
        service.update_config(cdh.dependencies_for(service))

        cmhost = management.get_cmhost()

        soy = service.get_role_config_group("{0}-SPARK_YARN_HISTORY_SERVER-BASE".format(service_name))
        soy.update_config({"log_dir": LOG_DIR + "/spark"})
        cdh.create_service_role(service, "SPARK_YARN_HISTORY_SERVER", cmhost)

        for host in management.get_hosts(include_cm_host=True):
            cdh.create_service_role(service, "GATEWAY", host)

        check.status_for_command("Execute command CreateSparkUserDirCommand on service Spark", service._cmd('CreateSparkUserDirCommand'))
        check.status_for_command("Execute command CreateSparkHistoryDirCommand on service Spark", service._cmd('CreateSparkHistoryDirCommand'))
        check.status_for_command("Execute command SparkUploadJarServiceCommand on service Spark", service._cmd('SparkUploadJarServiceCommand'))


def setup_yarn(HA):
    api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
    cluster = api.get_cluster(cmx.cluster_name)
    service_type = "YARN"
    if cdh.get_service_type(service_type) is None:
        print "> %s" % service_type
        service_name = "yarn"
        print "Create %s service" % service_name
        cluster.create_service(service_name, service_type)
        service = cluster.get_service(service_name)
        hosts = management.get_hosts()
        # Service-Wide
        service.update_config(cdh.dependencies_for(service))

        # empty list so it won't use ephemeral drive
        default_yarn_dir_list = ""

        yarn_dir_list = default_yarn_dir_list

        for x in range(int(diskcount)):
            yarn_dir_list += ",/data%d/yarn/nm" % (x)

        cmhost = management.get_cmhost()
        rm_host_id = [host for host in hosts if host.id == 0][0]
        srm_host_id = [host for host in hosts if host.id == 1][0]

        if not HA:
            rm_host_id = cmhost
            srm_host_id = cmhost

        for rcg in [x for x in service.get_all_role_config_groups()]:
            if rcg.roleType == "RESOURCEMANAGER":
                # yarn-RESOURCEMANAGER - Default Group
                rcg.update_config({"resource_manager_java_heapsize": "2000000000",
                                   "yarn_scheduler_minimum_allocation_mb": "1024",
                                   "yarn_scheduler_maximum_allocation_mb": "8192",
                                   "yarn_scheduler_maximum_allocation_vcores": "2",
                                   "resource_manager_log_dir": LOG_DIR + "/hadoop-yarn"})
                cdh.create_service_role(service, rcg.roleType, rm_host_id)
            if rcg.roleType == "JOBHISTORY":
                # yarn-JOBHISTORY - Default Group
                rcg.update_config({"mr2_jobhistory_java_heapsize": "1000000000", "mr2_jobhistory_log_dir": LOG_DIR + "/hadoop-mapreduce"})
                cdh.create_service_role(service, rcg.roleType, cmhost)

            if rcg.roleType == "NODEMANAGER":
                # yarn-NODEMANAGER - Default Group
                rcg.update_config({"yarn_nodemanager_heartbeat_interval_ms": "100",
                                   "node_manager_java_heapsize": "2000000000",
                                   "yarn_nodemanager_local_dirs": yarn_dir_list,
                                   "yarn_nodemanager_resource_cpu_vcores": getParameterValue(cmx.vmsize, "yarn_nodemanager_resource_cpu_vcores"),
                                   "yarn_nodemanager_resource_memory_mb": getParameterValue(cmx.vmsize, "yarn_nodemanager_resource_memory_mb"),
                                   "node_manager_log_dir": LOG_DIR + "/hadoop-yarn",
                                   "yarn_nodemanager_log_dirs": LOG_DIR + "/hadoop-yarn/container"})

            if rcg.roleType == "GATEWAY":
                # yarn-GATEWAY - Default Group
                rcg.update_config({"mapred_submit_replication": "3",
                                   "mapreduce_map_java_opts": getParameterValue(cmx.vmsize, "mapreduce_map_java_opts"),
                                   "mapreduce_reduce_java_opts": getParameterValue(cmx.vmsize, "mapreduce_reduce_java_opts"),
                                   "io_file_buffer_size": "131072",
                                   "io_sort_mb": "1024",
                                   "yarn_app_mapreduce_am_resource_mb": "4096",
                                   "yarn_app_mapreduce_am_max_heap": "1073741824"})
                for host in management.get_hosts(include_cm_host=True):
                    cdh.create_service_role(service, rcg.roleType, host)

        #print rm_host_id.hostId
        #print srm_host_id.hostId
        for role_type in ['NODEMANAGER']:
            for host in management.get_hosts(include_cm_host=False):
                if host.hostId != rm_host_id.hostId:
                    if host.hostId != srm_host_id.hostId:
                        cdh.create_service_role(service, role_type, host)

        check.status_for_command("Creating MR2 job history directory", service.create_yarn_job_history_dir())
        check.status_for_command("Creating NodeManager remote application log directory", service.create_yarn_node_manager_remote_app_log_dir())

    if HA:
        setup_yarn_ha()


def setup_mapreduce(HA):
    api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
    cluster = api.get_cluster(cmx.cluster_name)
    service_type = "MAPREDUCE"
    if cdh.get_service_type(service_type) is None:
        print "> %s" % service_type
        service_name = "mapreduce"
        print "Create %s service" % service_name
        cluster.create_service(service_name, service_type)
        service = cluster.get_service(service_name)
        hosts = management.get_hosts()

        jk = management.get_cmhost()
        if HA:
            jk = [x for x in hosts if x.id == 0][0]

        # Service-Wide
        service.update_config(cdh.dependencies_for(service))

        for rcg in [x for x in service.get_all_role_config_groups()]:
            if rcg.roleType == "JOBTRACKER":
                # mapreduce-JOBTRACKER - Default Group
                rcg.update_config({"jobtracker_mapred_local_dir_list": "/mapred/jt"})
                cdh.create_service_role(service, rcg.roleType, jk)
            if rcg.roleType == "TASKTRACKER":
                # mapreduce-TASKTRACKER - Default Group
                rcg.update_config({"tasktracker_mapred_local_dir_list": "/mapred/local",
                                   "mapred_tasktracker_map_tasks_maximum": "1",
                                   "mapred_tasktracker_reduce_tasks_maximum": "1", })
            if rcg.roleType == "GATEWAY":
                # mapreduce-GATEWAY - Default Group
                rcg.update_config({"mapred_reduce_tasks": "1", "mapred_submit_replication": "1",
                                   "mapred_map_memory_mb": "4096",
                                   "mapred_map_cpu_vcores": "1",
                                   "mapred_reduce_memory_mb": "8192",
                                   "mapred_reduce_cpu_vcores": "1",
                                   "mapred_map_java_opts_max_heap": "1024"})

        for role_type in ['GATEWAY', 'TASKTRACKER']:
            for host in management.get_hosts(include_cm_host=(role_type == 'GATEWAY')):
                cdh.create_service_role(service, role_type, host)


def setup_hive():
    api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
    cluster = api.get_cluster(cmx.cluster_name)
    service_type = "HIVE"
    if cdh.get_service_type(service_type) is None:
        print "> %s" % service_type
        service_name = "hive"
        print "Create %s service" % service_name
        cluster.create_service(service_name, service_type)
        service = cluster.get_service(service_name)
        hosts = management.get_hosts()

        # Service-Wide
        # hive_metastore_database_host: Assuming embedded DB is running from where embedded-db is located.
        service_config = {"hive_metastore_database_host": socket.getfqdn(cmx.cm_server),
                          "hive_metastore_database_user": "hive",
                          "hive_metastore_database_name": "metastore",
                          "hive_metastore_database_password": cmx.hive_password,
                          "hive_metastore_database_port": "5432",
                          "hive_metastore_database_type": "postgresql"}
        service_config.update(cdh.dependencies_for(service))
        service.update_config(service_config)

        hcat = service.get_role_config_group("{0}-WEBHCAT-BASE".format(service_name))
        hcat.update_config({"hcatalog_log_dir": LOG_DIR + "/hcatalog"})
        hs2 = service.get_role_config_group("{0}-HIVESERVER2-BASE".format(service_name))
        hs2.update_config({"hive_log_dir": LOG_DIR + "/hive"})
        hms = service.get_role_config_group("{0}-HIVEMETASTORE-BASE".format(service_name))
        hms.update_config({"hive_log_dir": LOG_DIR + "/hive"})

        # install to CM node, mingrui
        cmhost = management.get_cmhost()
        for role_type in ['HIVEMETASTORE', 'HIVESERVER2']:
            cdh.create_service_role(service, role_type, cmhost)

        for host in management.get_hosts(include_cm_host=True):
            cdh.create_service_role(service, "GATEWAY", host)

        check.status_for_command("Creating Hive Metastore Database Tables", service.create_hive_metastore_tables())
        check.status_for_command("Creating Hive user directory", service.create_hive_userdir())
        check.status_for_command("Creating Hive warehouse directory", service.create_hive_warehouse())


def setup_sqoop():
    api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
    cluster = api.get_cluster(cmx.cluster_name)
    service_type = "SQOOP"
    if cdh.get_service_type(service_type) is None:
        print "> %s" % service_type
        service_name = "sqoop"
        print "Create %s service" % service_name
        cluster.create_service(service_name, service_type)
        service = cluster.get_service(service_name)
        hosts = management.get_hosts()

        # Service-Wide
        service.update_config(cdh.dependencies_for(service))

        # install to CM node, mingrui
        cmhost = management.get_cmhost()
        cdh.create_service_role(service, "SQOOP_SERVER", cmhost)

        check.status_for_command("Creating Sqoop 2 user directory", service.create_sqoop_user_dir())


def setup_sqoop_client():
    api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
    cluster = api.get_cluster(cmx.cluster_name)
    service_type = "SQOOP_CLIENT"
    if cdh.get_service_type(service_type) is None:
        print "> %s" % service_type
        service_name = "sqoop_client"
        print "Create %s service" % service_name
        cluster.create_service(service_name, service_type)
        service = cluster.get_service(service_name)
        # hosts = get_cluster_hosts()

        # Service-Wide
        service.update_config({})

        for host in management.get_hosts(include_cm_host=True):
            cdh.create_service_role(service, "GATEWAY", host)


def setup_impala(HA):
    default_impala_dir_list = ""
    impala_dir_list = default_impala_dir_list

    for x in range(int(diskcount)):
        impala_dir_list += "/data%d/impala/scratch" % (x)
        max_count = int(diskcount) - 1
        if x < max_count:
            impala_dir_list += ","
            print "x is %d. Adding comma" % (x)

    api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
    cluster = api.get_cluster(cmx.cluster_name)
    service_type = "IMPALA"
    if cdh.get_service_type(service_type) is None:
        print "> %s" % service_type
        service_name = "impala"
        print "Create %s service" % service_name
        cluster.create_service(service_name, service_type)
        service = cluster.get_service(service_name)
        service_config = {"impala_cmd_args_safety_valve": "-scratch_dirs=%s" % (impala_dir_list)}
        service.update_config(service_config)
        service = cluster.get_service(service_name)
        hosts = management.get_hosts()

        # Service-Wide
        service.update_config(cdh.dependencies_for(service))

        impalad = service.get_role_config_group(
            "{0}-IMPALAD-BASE".format(service_name))
        impalad.update_config({"log_dir": LOG_DIR + "/impalad",
                               "impalad_memory_limit": getParameterValue(cmx.vmsize, "impalad_memory_limit")})
        ss = service.get_role_config_group("{0}-STATESTORE-BASE".format(service_name))
        ss.update_config({"log_dir": LOG_DIR + "/statestore"})
        cs = service.get_role_config_group("{0}-CATALOGSERVER-BASE".format(service_name))
        cs.update_config({"log_dir": LOG_DIR + "/catalogd"})

        cmhost = management.get_cmhost()
        for role_type in ['CATALOGSERVER', 'STATESTORE']:
            cdh.create_service_role(service, role_type, cmhost)

        if HA:
            # Install ImpalaD
            head_node_1_host_id = [host for host in hosts if host.id == 0][0]
            head_node_2_host_id = [host for host in hosts if host.id == 1][0]

            for host in hosts:
                # impalad should not be on hn-1 and hn-2
                if (host.id != head_node_1_host_id.id and host.id != head_node_2_host_id.id):
                    cdh.create_service_role(service, "IMPALAD", host)
        else:
            # All master services on CM host, install impalad on datanode host
            for host in hosts:
                if (host.id != cmhost.id):
                    cdh.create_service_role(service, "IMPALAD", host)

        check.status_for_command("Creating Impala user directory", service.create_impala_user_dir())
        check.status_for_command("Starting Impala Service", service.start())


def setup_oozie():
    api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
    cluster = api.get_cluster(cmx.cluster_name)
    service_type = "OOZIE"
    if cdh.get_service_type(service_type) is None:
        print "> %s" % service_type
        service_name = "oozie"
        print "Create %s service" % service_name
        cluster.create_service(service_name, service_type)
        service = cluster.get_service(service_name)
        hosts = management.get_hosts()

        # Service-Wide
        service.update_config(cdh.dependencies_for(service))

        # Role Config Group equivalent to Service Default Group
        # install to CM server, mingrui
        cmhost = management.get_cmhost()
        for rcg in [x for x in service.get_all_role_config_groups()]:
            if rcg.roleType == "OOZIE_SERVER":
                rcg.update_config({"oozie_log_dir": LOG_DIR + "/oozie", "oozie_data_dir": LOG_DIR + "/lib/oozie/data"})
                cdh.create_service_role(service, rcg.roleType, cmhost)

        check.status_for_command("Creating Oozie database", service.create_oozie_db())
        check.status_for_command("Installing Oozie ShareLib in HDFS", service.install_oozie_sharelib())


def setup_hue():
    api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
    cluster = api.get_cluster(cmx.cluster_name)
    service_type = "HUE"
    if cdh.get_service_type(service_type) is None:
        print "> %s" % service_type
        service_name = "hue"
        print "Create %s service" % service_name
        cluster.create_service(service_name, service_type)
        service = cluster.get_service(service_name)
        hosts = management.get_hosts()

        # Service-Wide
        service.update_config(cdh.dependencies_for(service))

        # Role Config Group equivalent to Service Default Group
        # install to CM, mingrui
        cmhost = management.get_cmhost()
        for rcg in [x for x in service.get_all_role_config_groups()]:
            if rcg.roleType == "HUE_SERVER":
                rcg.update_config({"hue_server_log_dir": LOG_DIR + "/hue"})
                cdh.create_service_role(service, "HUE_SERVER", cmhost)
            if rcg.roleType == "KT_RENEWER":
                rcg.update_config({"kt_renewer_log_dir": LOG_DIR + "/hue"})


def setup_flume():
    api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
    cluster = api.get_cluster(cmx.cluster_name)
    service_type = "FLUME"
    if cdh.get_service_type(service_type) is None:
        service_name = "flume"
        cluster.create_service(service_name.lower(), service_type)
        service = cluster.get_service(service_name)

        # Service-Wide
        service.update_config(cdh.dependencies_for(service))
        hosts = management.get_hosts()
        cdh.create_service_role(service, "AGENT", [x for x in hosts if x.id == 0][0])


def setup_hdfs_ha():
    try:
        print "> Setup HDFS-HA"
        hdfs = cdh.get_service_type('HDFS')
        zookeeper = cdh.get_service_type('ZOOKEEPER')

        # Requirement Hive/Hue
        hive = cdh.get_service_type('HIVE')
        hue = cdh.get_service_type('HUE')
        hosts = management.get_hosts()

        nn = [x for x in hosts if x.id == 0][0]
        snn = [x for x in hosts if x.id == 1][0]
        cm = management.get_cmhost()

        if len(hdfs.get_roles_by_type("NAMENODE")) != 2:
            # QJM require 3 nodes
            jn = random.sample([x.hostRef.hostId for x in hdfs.get_roles_by_type("DATANODE")], 3)
            # get NAMENODE and SECONDARYNAMENODE hostId
            nn_host_id = hdfs.get_roles_by_type("NAMENODE")[0].hostRef.hostId
            sndnn_host_id = hdfs.get_roles_by_type("SECONDARYNAMENODE")[0].hostRef.hostId

            # Occasionally SECONDARYNAMENODE is also installed on the NAMENODE
            if nn_host_id == sndnn_host_id:
                standby_host_id = random.choice(
                    [x.hostId for x in jn if x.hostId not in [nn_host_id, sndnn_host_id]])
            elif nn_host_id is not sndnn_host_id:
                standby_host_id = sndnn_host_id
            else:
                standby_host_id = random.choice(
                    [x.hostId for x in hosts if x.hostId is not nn_host_id])

            # hdfs-JOURNALNODE - Default Group
            role_group = hdfs.get_role_config_group(
                "%s-JOURNALNODE-BASE" % hdfs.name)
            role_group.update_config(
                {"dfs_journalnode_edits_dir": "/data/dfs/jn"})

            cmd = hdfs.enable_nn_ha(hdfs.get_roles_by_type("NAMENODE")[0].name, standby_host_id,
                                    "nameservice1", [dict(jnHostId=nn_host_id), dict(
                                        jnHostId=sndnn_host_id), dict(jnHostId=cm.hostId)],
                                    zk_service_name=zookeeper.name)
            check.status_for_command("Enable HDFS-HA - [ http://%s:7180/cmf/command/%s/details ]" %
                                     (socket.getfqdn(cmx.cm_server), cmd.id), cmd)

            # hdfs-HTTPFS
            cdh.create_service_role(
                hdfs, "HTTPFS", [x for x in hosts if x.id == 0][0])
            # Configure HUE service dependencies
            cdh('HDFS').stop()
            cdh('ZOOKEEPER').stop()

            if hue is not None:
                hue.update_config(cdh.dependencies_for(hue))
            if hive is not None:
                check.status_for_command(
                    "Update Hive Metastore NameNodes", hive.update_metastore_namenodes())

            cdh('ZOOKEEPER').start()
            cdh('HDFS').start()

    except ApiException as err:
        print " ERROR: %s" % err.message


def setup_yarn_ha():
    print "> Setup YARN-HA"
    yarn = cdh.get_service_type('YARN')
    zookeeper = cdh.get_service_type('ZOOKEEPER')
    hosts = management.get_hosts()
    # hosts = api.get_all_hosts()
    if len(yarn.get_roles_by_type("RESOURCEMANAGER")) != 2:
        # Choose secondary name node for standby RM
        rm = [x for x in hosts if x.id == 1][0]

        cmd = yarn.enable_rm_ha(rm.hostId, zookeeper.name)
        check.status_for_command("Enable YARN-HA - [ http://%s:7180/cmf/command/%s/details ]" %
                                 (socket.getfqdn(cmx.cm_server), cmd.id), cmd)


def setup_kerberos():
    print "> Setup Kerberos"
    hdfs = cdh.get_service_type('HDFS')
    zookeeper = cdh.get_service_type('ZOOKEEPER')
    hue = cdh.get_service_type('HUE')
    hosts = management.get_hosts()

    # HDFS Service-Wide
    hdfs.update_config({"hadoop_security_authentication": "kerberos",
                        "hadoop_security_authorization": True})

    # hdfs-DATANODE-BASE - Default Group
    role_group = hdfs.get_role_config_group("%s-DATANODE-BASE" % hdfs.name)
    role_group.update_config({"dfs_datanode_http_port": "1006", "dfs_datanode_port": "1004",
                              "dfs_datanode_data_dir_perm": "700"})

    # Zookeeper Service-Wide
    zookeeper.update_config({"enableSecurity": True})
    cdh.create_service_role(
        hue, "KT_RENEWER", [x for x in hosts if x.id == 0][0])


def setup_sentry():
    api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
    cluster = api.get_cluster(cmx.cluster_name)
    service_type = "SENTRY"
    if cdh.get_service_type(service_type) is None:
        service_name = "sentry"
        cluster.create_service(service_name.lower(), service_type)
        service = cluster.get_service(service_name)

        # Service-Wide
        # sentry_server_database_host: Assuming embedded DB is running from where embedded-db is located.
        service_config = {"sentry_server_database_host": socket.getfqdn(cmx.cm_server),
                          "sentry_server_database_user": "sentry",
                          "sentry_server_database_name": "sentry",
                          "sentry_server_database_password": "cloudera",
                          "sentry_server_database_port": "5432",
                          "sentry_server_database_type": "postgresql"}

        service_config.update(cdh.dependencies_for(service))
        service.update_config(service_config)
        hosts = management.get_hosts()

        # Mingrui install sentry to cm host
        cmhost = management.get_cmhost()
        cdh.create_service_role(service, "SENTRY_SERVER", cmhost)
        check.status_for_command(
            "Creating Sentry Database Tables", service.create_sentry_database_tables())

        # Update configuration for Hive service
        hive = cdh.get_service_type('HIVE')
        hive.update_config(cdh.dependencies_for(hive))

        # Disable HiveServer2 Impersonation - hive-HIVESERVER2-BASE - Default Group
        role_group = hive.get_role_config_group("%s-HIVESERVER2-BASE" % hive.name)
        role_group.update_config({"hiveserver2_enable_impersonation": False})


def setup_easy():
    api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
    cluster = api.get_cluster(cmx.cluster_name)
    print "> Easy setup for cluster: %s" % cmx.cluster_name
    # Do not install these services
    do_not_install = ['KEYTRUSTEE', 'KMS', 'KS_INDEXER', 'ISILON', 'FLUME', 'MAPREDUCE', 'ACCUMULO',
                      'ACCUMULO16', 'SPARK_ON_YARN', 'SPARK', 'SOLR', 'SENTRY']
    service_types = list(set(cluster.get_service_types()) - set(do_not_install))

    for service in service_types:
        cluster.create_service(name=service.lower(),
                               service_type=service.upper())

    cluster.auto_assign_roles()
    cluster.auto_configure()

    # Hive Metastore DB and dependencies ['YARN', 'ZOOKEEPER']
    service = cdh.get_service_type('HIVE')
    service_config = {"hive_metastore_database_host": socket.getfqdn(cmx.cm_server),
                      "hive_metastore_database_user": "hive",
                      "hive_metastore_database_name": "metastore",
                      "hive_metastore_database_password": cmx.hive_password,
                      "hive_metastore_database_port": "5432",
                      "hive_metastore_database_type": "postgresql"}
    service_config.update(cdh.dependencies_for(service))
    service.update_config(service_config)
    check.status_for_command(
        "Executing first run command. This might take a while.", cluster.first_run())


def teardown(keep_cluster=True):
    api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
    try:
        cluster = api.get_cluster(cmx.cluster_name)
        service_list = cluster.get_all_services()
        print "> Teardown Cluster: %s Services and keep_cluster: %s" % (
            cmx.cluster_name, keep_cluster)
        check.status_for_command("Stop %s" % cmx.cluster_name, cluster.stop())

        for service in service_list[:None:-1]:
            try:
                check.status_for_command(
                    "Stop Service %s" % service.name, service.stop())
            except ApiException as err:
                print " ERROR: %s" % err.message

            print "Processing service %s" % service.name
            for role in service.get_all_roles():
                print " Delete role %s" % role.name
                service.delete_role(role.name)

            cluster.delete_service(service.name)
    except ApiException as err:
        print err.message
        exit(1)

    # Delete Management Services
    try:
        mgmt = api.get_cloudera_manager()
        check.status_for_command(
            "Stop Management services", mgmt.get_service().stop())
        mgmt.delete_mgmt_service()
    except ApiException as err:
        print " ERROR: %s" % err.message

    # cluster.remove_all_hosts()
    if not keep_cluster:
        # Remove CDH Parcel and GPL Extras Parcel
        for x in cmx.parcel:
            print "Removing parcel: [ %s-%s ]" % (x['product'], x['version'])
            parcel_product = x['product']
            parcel_version = x['version']

            while True:
                parcel = cluster.get_parcel(parcel_product, parcel_version)
                if parcel.stage == 'ACTIVATED':
                    print "Deactivating parcel"
                    parcel.deactivate()
                else:
                    break

            while True:
                parcel = cluster.get_parcel(parcel_product, parcel_version)
                if parcel.stage == 'DISTRIBUTED':
                    print "Executing parcel.start_removal_of_distribution()"
                    parcel.start_removal_of_distribution()
                    print "Executing parcel.remove_download()"
                    parcel.remove_download()
                elif parcel.stage == 'UNDISTRIBUTING':
                    msg = " [%s: %s / %s]" % (parcel.stage,
                                              parcel.state.progress, parcel.state.totalProgress)
                    sys.stdout.write(msg + " " * (78 - len(msg)) + "\r")
                    sys.stdout.flush()
                else:
                    break

        print "Deleting cluster: %s" % cmx.cluster_name
        api.delete_cluster(cmx.cluster_name)


class ManagementActions:
    def __init__(self, *role_list):
        self._role_list = role_list
        self._api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
        self._cm = self._api.get_cloudera_manager()
        try:
            self._service = self._cm.get_service()
        except ApiException:
            self._service = self._cm.create_mgmt_service(ApiServiceSetupInfo())
        self._role_types = [x.type for x in self._service.get_all_roles()]

    def stop(self):
        self._action('stop_roles')

    def start(self):
        self._action('start_roles')

    def restart(self):
        self._action('restart_roles')

    def _action(self, action):
        state = {'start_roles': ['STOPPED'], 'stop_roles': ['STARTED'], 'restart_roles': ['STARTED', 'STOPPED']}
        for mgmt_role in [x for x in self._role_list if x in self._role_types]:
            for role in [x for x in self._service.get_roles_by_type(mgmt_role) if x.roleState in state[action]]:
                for cmd in getattr(self._service, action)(role.name):
                    check.status_for_command("%s role %s" % (action.split("_")[0].upper(), mgmt_role), cmd)

    def setup(self):
        # api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
        print "> Setup Management Services"
        self._cm.update_config({"TSQUERY_STREAMS_LIMIT": 1000})
        hosts = management.get_hosts(include_cm_host=True)
        # pick hostId that match the ipAddress of cm_server
        # mgmt_host may be empty then use the 1st host from the -w
        try:
            mgmt_host = [x for x in hosts if x.ipAddress == socket.gethostbyname(cmx.cm_server)][0]
        except IndexError:
            mgmt_host = [x for x in hosts if x.id == 0][0]

        for role_type in [x for x in self._service.get_role_types() if x in self._role_list]:
            try:
                if not [x for x in self._service.get_all_roles() if x.type == role_type]:
                    print "Creating Management Role %s " % role_type
                    role_name = "mgmt-%s-%s" % (role_type, mgmt_host.md5host)
                    for cmd in self._service.create_role(role_name, role_type, mgmt_host.hostId).get_commands():
                        check.status_for_command("Creating %s" % role_name, cmd)
            except ApiException as err:
                print "ERROR: %s " % err.message

        # now configure each role
        for group in [x for x in self._service.get_all_role_config_groups() if x.roleType in self._role_list]:
            if group.roleType == "ACTIVITYMONITOR":
                group.update_config({"firehose_database_host": "%s:5432" % socket.getfqdn(cmx.cm_server),
                                     "firehose_database_user": "amon",
                                     "firehose_database_password": cmx.amon_password,
                                     "firehose_database_type": "postgresql",
                                     "firehose_database_name": "amon",
                                     "mgmt_log_dir": LOG_DIR + "/cloudera-scm-firehose",
                                     "firehose_heapsize": "215964392"})
            elif group.roleType == "ALERTPUBLISHER":
                group.update_config({"mgmt_log_dir": LOG_DIR + "/cloudera-scm-alertpublisher"})
            elif group.roleType == "EVENTSERVER":
                group.update_config({"event_server_heapsize": "215964392", "mgmt_log_dir": LOG_DIR + "/cloudera-scm-eventserver", "eventserver_index_dir": LOG_DIR + "/lib/cloudera-scm-eventserver"})
            elif group.roleType == "HOSTMONITOR":
                group.update_config({"mgmt_log_dir": LOG_DIR + "/cloudera-scm-firehose", "firehose_storage_dir": LOG_DIR + "/lib/cloudera-host-monitor"})
            elif group.roleType == "SERVICEMONITOR":
                group.update_config({"mgmt_log_dir": LOG_DIR + "/cloudera-scm-firehose", "firehose_storage_dir": LOG_DIR + "/lib/cloudera-service-monitor"})
            elif group.roleType == "NAVIGATOR" and management.licensed():
                group.update_config({})
            elif group.roleType == "NAVIGATORMETADATASERVER" and management.licensed():
                group.update_config({})
            elif group.roleType == "REPORTSMANAGER" and management.licensed():
                group.update_config({"headlamp_database_host": "%s:5432" % socket.getfqdn(cmx.cm_server),
                                     "headlamp_database_name": "rman",
                                     "headlamp_database_password": cmx.rman_password,
                                     "headlamp_database_type": "postgresql",
                                     "headlamp_database_user": "rman",
                                     "headlamp_scratch_dir": LOG_DIR + "/lib/cloudera-scm-headlamp",
                                     "mgmt_log_dir": LOG_DIR + "/cloudera-scm-headlamp"})
            elif group.roleType == "OOZIE":
                group.update_config({"oozie_database_host": "%s:5432" % socket.getfqdn(cmx.cm_server),
                                     "oozie_database_name": "oozie",
                                     "oozie_database_password": cmx.oozie_password,
                                     "oozie_database_type": "postgresql",
                                     "oozie_database_user": "oozie",
                                     "oozie_log_dir": LOG_DIR + "/oozie"})

    @classmethod
    def licensed(cls):
        api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
        cm = api.get_cloudera_manager()
        try:
            return bool(cm.get_license().uuid)
        except ApiException as err:
            return "Express" not in err.message

    @classmethod
    def upload_license(cls):
        api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
        cm = api.get_cloudera_manager()
        if cmx.license_file and not management.licensed():
            print "Upload license"
            with open(cmx.license_file, 'r') as f:
                license_contents = f.read()
                print "Upload CM License: \n %s " % license_contents
                cm.update_license(license_contents)
                # REPORTSMANAGER required after applying license
                management("REPORTSMANAGER").setup()
                management("REPORTSMANAGER").start()

    @classmethod
    def begin_trial(cls):
        api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
        print "def begin_trial"
        if not management.licensed():
            try:
                api.post("/cm/trial/begin")
                # REPORTSMANAGER required after applying license
                management("REPORTSMANAGER").setup()
                management("REPORTSMANAGER").start()
            except ApiException as err:
                print err.message

    @classmethod
    def get_mgmt_password(cls, role_type):
        contents = []
        mgmt_password = False

        if os.path.exists('/etc/cloudera-scm-server'):
            file_path = os.path.join(
                '/etc/cloudera-scm-server', 'db.mgmt.properties')
            try:
                with open(file_path) as f:
                    contents = f.readlines()
            except IOError:
                print "Unable to open file %s." % file_path

        # role_type expected to be in
        # ACTIVITYMONITOR, REPORTSMANAGER, NAVIGATOR, OOZIE, HIVEMETASTORESERVER
        if role_type in ['ACTIVITYMONITOR', 'REPORTSMANAGER', 'NAVIGATOR', 'OOZIE', 'HIVEMETASTORESERVER']:
            idx = "com.cloudera.cmf.%s.db.password=" % role_type
            match = [s.rstrip('\n') for s in contents if idx in s][0]
            mgmt_password = match[match.index(idx) + len(idx):]

        return mgmt_password

    @classmethod
    def get_cmhost(cls):
        api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
        idx = len(set(enumerate(cmx.host_names)))
        _host = [x for x in api.get_all_hosts() if x.ipAddress == socket.gethostbyname(cmx.cm_server)][0]
        cmhost = {
            'id': idx,
            'hostId': _host.hostId,
            'hostname': _host.hostname,
            'md5host': hashlib.md5(_host.hostname).hexdigest(),
            'ipAddress': _host.ipAddress,
        }

        return type('', (), cmhost)

    @classmethod
    def get_hosts(cls, include_cm_host=False):
        api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
        w_hosts = set(enumerate(cmx.host_names))
        if include_cm_host and socket.gethostbyname(cmx.cm_server) not in [socket.gethostbyname(x) for x in cmx.host_names]:
            w_hosts.add((len(w_hosts), cmx.cm_server))

        hosts = []
        for idx, host in w_hosts:
            _host = [x for x in api.get_all_hosts() if x.ipAddress == socket.gethostbyname(host)][0]
            hosts.append({
                'id': idx,
                'hostId': _host.hostId,
                'hostname': _host.hostname,
                'md5host': hashlib.md5(_host.hostname).hexdigest(),
                'ipAddress': _host.ipAddress,
            })

        return [type('', (), x) for x in hosts]

    @classmethod
    def restart_management(cls):
        api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
        mgmt = api.get_cloudera_manager().get_service()
        check.status_for_command("Stop Management services", mgmt.stop())
        check.status_for_command("Start Management services", mgmt.start())


class ServiceActions:
    def __init__(self, *service_list):
        self._service_list = service_list
        self._api = ApiResource(server_host=cmx.cm_server,
                                username=cmx.username, password=cmx.password)
        self._cluster = self._api.get_cluster(cmx.cluster_name)

    def stop(self):
        self._action('stop')

    def start(self):
        self._action('start')

    def restart(self):
        self._action('restart')

    def _action(self, action):
        state = {'start': ['STOPPED'], 'stop': [
            'STARTED'], 'restart': ['STARTED', 'STOPPED']}
        for services in [x for x in self._cluster.get_all_services() if x.type in self._service_list and x.serviceState in state[action]]:
            check.status_for_command("%s service %s" % (action.upper(), services.type), getattr(self._cluster.get_service(services.name), action)())

    @classmethod
    def get_service_type(cls, name):
        api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
        cluster = api.get_cluster(cmx.cluster_name)
        try:
            service = [x for x in cluster.get_all_services() if x.type == name][0]
        except IndexError:
            service = None

        return service

    @classmethod
    def deploy_client_config_for(cls, obj):
        api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
        if isinstance(obj, str) or isinstance(obj, unicode):
            for role_name in [x.roleName for x in api.get_host(obj).roleRefs if 'GATEWAY' in x.roleName]:
                service = cdh.get_service_type('GATEWAY')
                print "Deploying client config for service: %s - host: [%s]" % (service.type, api.get_host(obj).hostname)
                check.status_for_command("Deploy client config for role %s" % role_name, service.deploy_client_config(role_name))
        elif isinstance(obj, ApiService):
            for role in obj.get_roles_by_type("GATEWAY"):
                check.status_for_command("Deploy client config for role %s" % role.name, obj.deploy_client_config(role.name))

    @classmethod
    def create_service_role(cls, service, role_type, host):
        service_name = service.name[:4] + hashlib.md5(service.name).hexdigest()[:8] if len(role_type) > 24 else service.name
        role_name = "-".join([service_name, role_type, host.md5host])[:64]
        print "Creating role: %s on host: [%s]" % (role_name, host.hostname)
        for cmd in service.create_role(role_name, role_type, host.hostId).get_commands():
            check.status_for_command("Creating role: %s on host: [%s]" % (role_name, host.hostname), cmd)

    @classmethod
    def restart_cluster(cls):
        api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)
        cluster = api.get_cluster(cmx.cluster_name)
        print "Restart cluster: %s" % cmx.cluster_name
        check.status_for_command("Stop %s" % cmx.cluster_name, cluster.stop())
        check.status_for_command("Start %s" % cmx.cluster_name, cluster.start())
        # Example deploying cluster wide Client Config
        check.status_for_command("Deploy client config for %s" % cmx.cluster_name, cluster.deploy_client_config())

    @classmethod
    def dependencies_for(cls, service):
        service_config = {}
        config_types = {"hue_webhdfs": ['NAMENODE', 'HTTPFS'], "hdfs_service": "HDFS", "sentry_service": "SENTRY",
                        "zookeeper_service": "ZOOKEEPER", "hbase_service": "HBASE", "solr_service": "SOLR",
                        "hive_service": "HIVE", "sqoop_service": "SQOOP",
                        "impala_service": "IMPALA", "oozie_service": "OOZIE",
                        "mapreduce_yarn_service": ['MAPREDUCE', 'YARN'], "yarn_service": "YARN"}

        dependency_list = []
        # get required service config
        for k, v in service.get_config(view="full")[0].items():
            if v.required:
                dependency_list.append(k)

        # Extended dependence list, adding the optional ones as well
        if service.type == 'HUE':
            dependency_list.extend(['sqoop_service', 'impala_service'])
        if service.type in ['HIVE', 'HDFS', 'HUE', 'HBASE', 'OOZIE', 'MAPREDUCE', 'YARN']:
            dependency_list.append('zookeeper_service')
        if service.type == 'OOZIE':
            dependency_list.append('hive_service')
        if service.type in ['FLUME', 'SPARK', 'SENTRY']:
            dependency_list.append('hdfs_service')

        for key in dependency_list:
            if key == "hue_webhdfs":
                hdfs = cdh.get_service_type('HDFS')
                if hdfs is not None:
                    service_config[key] = [x.name for x in hdfs.get_roles_by_type('NAMENODE')][0]
                    # prefer HTTPS over NAMENODE
                    if [x.name for x in hdfs.get_roles_by_type('HTTPFS')]:
                        service_config[key] = [x.name for x in hdfs.get_roles_by_type('HTTPFS')][0]
            elif key == "mapreduce_yarn_service":
                for _type in config_types[key]:
                    if cdh.get_service_type(_type) is not None:
                        service_config[key] = cdh.get_service_type(_type).name
                    # prefer YARN over MAPREDUCE
                    if cdh.get_service_type(_type) is not None and _type == 'YARN':
                        service_config[key] = cdh.get_service_type(_type).name
            elif key == "hue_hbase_thrift":
                hbase = cdh.get_service_type('HBASE')
                if hbase is not None:
                    service_config[key] = [x.name for x in hbase.get_roles_by_type(config_types[key])][0]
            else:
                if cdh.get_service_type(config_types[key]) is not None:
                    service_config[key] = cdh.get_service_type(config_types[key]).name

        return service_config


class ActiveCommands:
    def __init__(self):
        self._api = ApiResource(server_host=cmx.cm_server, username=cmx.username, password=cmx.password)

    def status_for_command(self, message, command):
        _state = 0
        _bar = ['[|]', '[/]', '[-]', '[\\]']
        while True:
            if self._api.get("/commands/%s" % command.id)['active']:
                sys.stdout.write(_bar[_state] + ' ' + message + ' ' + ('\b' * (len(message) + 5)))
                sys.stdout.flush()
                _state += 1
                if _state > 3:
                    _state = 0
                time.sleep(2)
            else:
                print "\n [%s] %s" % (command.id, self._api.get("/commands/%s" % command.id)['resultMessage'])
                self._child_cmd(self._api.get("/commands/%s" % command.id)['children']['items'])
                break

    def _child_cmd(self, cmd):
        if len(cmd) != 0:
            print " Sub tasks result(s):"
            for resMsg in cmd:
                if resMsg.get('resultMessage'):
                    print "  [%s] %s" % (resMsg['id'], resMsg['resultMessage']) if not resMsg.get('roleRef') else "  [%s] %s - %s" % (resMsg['id'], resMsg['resultMessage'], resMsg['roleRef']['roleName'])
                self._child_cmd(self._api.get("/commands/%s" % resMsg['id'])['children']['items'])

def main():
    parser=setupArguments()
    options=parser.parse_args()
    options.host_names=options.host_names.split(",")
    print(options)

    wait_for_cm_to_start()
    api = ApiResource(server_host="localhost", username="admin", password="admin")
    init_cluster(api, options)
    add_hosts_to_cluster(api, options)

    '''
    deploy_parcel(parcel_product=cmx.parcel[0]['product'], parcel_version=cmx.parcel[0]['version'])
    mgmt_roles = ['SERVICEMONITOR', 'ALERTPUBLISHER', 'EVENTSERVER', 'HOSTMONITOR']
    if management.licensed():
        mgmt_roles.append('REPORTSMANAGER')
    management(*mgmt_roles).setup()
    management(*mgmt_roles).start()
    management.begin_trial()

    setup_zookeeper()
    setup_hdfs()
    setup_yarn()
    setup_spark_on_yarn()
    setup_hive()
    setup_impala()
    setup_oozie()
    setup_hue()

    cdh.restart_cluster()
    management(*mgmt_roles).restart()
    '''

main()
