# WIP - Azure Deployment Guide for Mattermost

!!!Danger
    This guide is a **Work in Progress**!

    **Details are under review, may be untested, and should be expected to be incomplete and unfit for purpose.**

A Step-by-Step Guide to Creating and Configuring Mattermost on AWS

## 1. Preparation

### Permissions and Subscription

Ensure you have the necessary permissions to create and manage resources in Azure and have successfully created a subscription.

### Create a Mattermost Resource Group

- **Region:** (Choose a region to deploy your Mattermost Cluster)

### Create a Virtual Network

- **Resource Group:** Mattermost
- **Virtual Network Name:** mattermost

## 2. Database Setup

### Create an Azure Cosmos DB for PostgreSQL Cluster

#### Basics

- **Resource Group:** Mattermost
- **Cluster Name:** mattermost-db
- **Location:** Customer Choice
- **Scale:**
    - `2` nodes with high availability (HA) enabled (Aggregated 12 vCores / 96 GiB RAM)
    - **Node Count:** 2
    - **Compute per Node:** Customer Choice (Default: 4 vCores, 32 GiB RAM)
    - **Storage per Node:** Customer Choice (Default: 512 GB)
    - **High Availability:** (Customer Preference)
    - **PostgreSQL Version:** 16
    - **Database Name:** mattermost

#### Networking

- **Connectivity Method:** Private access
- **Create Private Endpoint**
    - **Resource Group:** Mattermost
    - **Virtual Network:** mattermost
    - **Subnet:** default

## 3. Mattermost App Nodes Setup

### Create a Virtual Machine Scale Set

#### Basics

- **Resource Group:** Mattermost
- **Virtual Machine Scale Set Name:** Mattermost
- **Orchestration Mode:** Flexible
- **Image:** Debian
- **Size:** (Select a size based on your node requirements. B series is sufficient for most needs.)
- **Administrator Account:**
    - **Authentication Type:** SSH public key

#### Networking

- **Virtual Network:** mattermost
- **Load Balancing Options:**
    - **Application Gateway**
        - **Select Application Gateway:** Create an Application Gateway
        - **Application Gateway Name:** mattermost
        - **IP Type:** Public only
        - **Routing Rule**
            - **Rule Name:** mattermost

#### Scaling

- **Initial Instance Count:** 2

### Installation and Configuration

- Install Mattermost on each node following the [official installation guide](https://docs.mattermost.com/).
- Set up networking and security groups to allow communication between the nodes and the PostgreSQL database.
- Configure Mattermost to connect to the PostgreSQL database by updating the `config.json` file on each node.

## 4. Create Object Storage

### Azure Blob Storage and Minio Container

- Setup details as per requirement.

## 5. Elasticsearch Setup (Optional)

- Create an Elasticsearch cluster on Azure following the [Azure Elasticsearch documentation](https://azure.microsoft.com/en-us/services/elasticsearch/).
- Configure the cluster to handle 1000 posts per minute for indexing and performance.
- Set up networking and security groups to allow communication between Elasticsearch, Mattermost app nodes, and other components.

## 6. Grafana and Prometheus Setup

- Install and configure Prometheus on a VM or AKS to collect metrics from the Mattermost app nodes following the [official Prometheus documentation](https://prometheus.io/docs/introduction/overview/).
- Install and configure Grafana on a VM or AKS to visualize the metrics collected by Prometheus following the [official Grafana documentation](https://grafana.com/docs/grafana/latest/).
- Set up data sources in Grafana to pull data from Prometheus and Elasticsearch.

## 7. Networking and Security

- Review and update networking configurations to ensure all components can communicate as needed.
- Update security groups and firewall rules to allow only necessary traffic.
- Ensure all resources are within the same Virtual Network or are properly peered.

## 8. Testing and Validation

- Test the setup by creating posts in Mattermost and verifying they are indexed in Elasticsearch.
- Verify metrics are being collected in Prometheus and can be visualized in Grafana.
- Test the Load Balancer to ensure it is distributing traffic correctly and handling WebSocket traffic.

## 9. Monitoring and Maintenance

- Set up Azure Monitor and Alerts to notify you of any issues.
- Regularly review the performance and security of your setup and make necessary adjustments.

## 10. Documentation

- Document the setup, configurations, and any customizations made.
- Ensure all admin users have access to the documentation for reference and troubleshooting.

## To Investigate

### Create an Application Gateway

#### Basics

- **Resource Group:** Mattermost
- **Application Gateway Name:** Mattermost
- **Minimum Instance Count:** 1
- **Virtual Network:** Create New
    - **Name:** mattermost_lb

#### Frontends

- **Public IP Address:** Add new
    - **Name:** mattermost

#### Backends

- **Name:** mattermost
- **Add Backend Pool Without Targets:** Yes
