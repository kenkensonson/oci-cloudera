import cm_client
from cm_client.rest import ApiException

def main():
    cm_client.configuration.username = 'admin'
    cm_client.configuration.password = 'admin'

    api_client = cm_client.ApiClient('http://localhost:7180/api/v30')
    cluster_api_instance = cm_client.ClustersResourceApi(api_client)

main()
