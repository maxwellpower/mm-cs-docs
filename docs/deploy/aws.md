# Deploying Mattermost Enterprise High-Availability via AWS

A Step-by-Step Guide to creating and configuring a VPC, Security Groups, Load Balancer, PostgreSQL Database, S3 Storage, Application Nodes, and Elasticsearch for Mattermost on Amazon Web Services.

## Network Resources

### 1. Create a VPC

Create a Virtual Private Cloud to keep the resources secure and allow them to communicate.

- Go to the AWS Management Console.
- Open the VPC Dashboard by selecting "**VPC**" under the "**Networking & Content Delivery**" section.
- **VPC and More**: Ensure "**VPC and More**" is selected to create the VPC with subnets, route tables, and other networking resources.
- **Name Tag Auto-Generation**: Check "**Auto-generate**" to have AWS automatically generate name tags for the VPC components.
- **Name Tag**: Enter a name for your VPC (e.g., `Mattermost-VPC`).
- **IPv4 CIDR Block**: Specify an IPv4 CIDR block for the VPC (e.g., `10.0.0.0/16`).
- **IPv6 CIDR Block**: If not required, select "No IPv6 CIDR Block".
- **Tenancy**: Select "Default" unless dedicated tenancy is required.
- **Number of Availability Zones (AZs)**: Choose `2` for high availability.
- **Number of Public Subnets**: Set to `2` for redundancy across multiple AZs.
- **Number of Private Subnets**: Set to `2` for redundancy across multiple AZs.
    - **Customize Subnet CIDR Blocks** (if necessary)
- **NAT gateways**: Select "**1 per AZ**" for fault tolerance and to allow private subnets to access the internet for updates and patching.
- **VPC endpoints**: S3 Gateway
- Enable "**Enable DNS hostnames**" and "**Enable DNS resolution**" to use DNS within your VPC.
- Review the settings and click "Create VPC".

### 2. Create and Configure Security Groups

Create Security Groups for communication between the various services. For each below, complete the following:

- Go to the EC2 Dashboard.
- Select "**Security Groups**" under "**Network & Security**" from the left-hand menu.
- Click "**Create security group**".

#### Load Balancer

- **Name**: Enter a name (e.g., `Mattermost-ALB-SG`).
- **Description**: Provide a description (e.g., "Security group for Mattermost ALB").
- **VPC**: Select the VPC you created (e.g., "Mattermost-VPC").
- **Inbound Rules**: Add rules to allow HTTP (port 80) and HTTPS (port 443) traffic from anywhere (0.0.0.0/0).
- **Outbound Rules**: Allow all outbound traffic.

#### Database

- **Name**: Enter a name (e.g., `Mattermost-DB-SG`).
- **Description**: Provide a description (e.g., "Security group for Mattermost database").
- **VPC**: Select the VPC you created.
- **Inbound Rules**: Allow `PostgreSQL` traffic (port 5432) from the application nodes security group.
- **Outbound Rules**: Allow all outbound traffic.

#### Application Nodes

- **Name**: Enter a name (e.g., `Mattermost-App-SG`).
- **Description**: Provide a description (e.g., "Security group for Mattermost application nodes").
- **VPC**: Select the VPC you created.
- **Inbound Rules**:
    - Allow `Custom TCP` (port 8065) from the ALB security group (`Mattermost-ALB-SG`).
    - Allow `PostgreSQL` (port 5432) from the DB security group (`Mattermost-DB-SG`)
    - Allow `SSH` traffic (port 22) from your IP address for management.
    - Allow `ALL` Traffic from within the security group (`Mattermost-App-SG`).
- **Outbound Rules**: Allow all outbound traffic.

### 3. Create a VPC Endpoint

The VPC endpoint will allow SSH access to compute resources inside the VPC.

- Go to the VPC dashboard and select "Endpoints" under "Virtual Private cloud"
- Click "Create endpoint"
- **Name tag**: `Mattermost-VPC-endpoint`
- **Service category**: EC2 Instance Connect Endpoint
- **VPC**: Select the VPC created earlier (Eg. `Mattermost-VPC`)
- Security groups: Select the App security group (Eg. `Mattermost-App-SG`)

## Load Balancer Configuration

### 4. Request an SSL/TLS Certificate

- Go to "**AWS Certificate Manager**" and select "Request certificate".
- **Certificate type**: Request a public certificate.
- **Domain names**:
    - Fully qualified domain name: `chat.example.com`.
- **Validation method**: DNS validation.
- **Key Algorithm**: RSA 2048.
- **DNS Validation**:
    - In the list of certificates, choose the Certificate ID of the certificate just created. This opens a details page for the certificate.
    - In the Domains section, complete one of the following two procedures:
        - **Option 1: Validate with Route 53.**
            - An active "**Create records**" in Route 53 button appears if the following conditions are true:
                - You use Route 53 as your DNS provider.
                - You have permission to write to the zone hosted by Route 53.
                - Your FQDN still needs to be validated.
            - Click the Create records in Route 53 button, then click Create records. The Certificate status page should open with a banner reporting successfully created DNS records.
        - **Option 2: Retrieve the CNAME information and add it to your DNS database.**
            - On the details page for the new certificate, you can do this in either of two ways:
                - Copy the CNAME components displayed in the Domains section. This information needs to be added manually to your DNS database.
                - Alternatively, choose Export to CSV. The information in the resulting file must be added manually to your DNS database.

### 5. Add Load Balancer Target Groups

- Go to the EC2 service and select "**Target Groups**" under "**Load Balancing**".
    - **Target Group Name**: Enter a name (e.g., `Mattermost-Targets`).
    - **Protocol**: Select `HTTP`.
    - **Port**: Enter `8065`.
    - **VPC**: Select the VPC created earlier.
    - **Health Checks**: Configure health checks for `api/v4/system/ping` to monitor instance health.
- Skip adding the EC2 nodes to the target group. We will add them later once they are created.

### 6. Set Up the Load Balancer

!!!Note
    If you are using SSL/TLS, ensure that the certificate generated earlier is "**Issued**," or it will not be available to be selected. Once the DNS records are updated, certificates can take 30 minutes to validate.

#### Create an Application Load Balancer (ALB)

- Go to the EC2 service and select "Load Balancers" under "Load Balancing".
- Click "Create Load Balancer" and select "Application Load Balancer".
- **Basic Configuration**:
    - **Load Balancer Name**: Enter a name for the ALB (e.g., `Mattermost-ALB`).
    - **Scheme**: Choose "internet-facing".
    - **IP Address Type**: Select "IPv4".
- **VPC**: Select the VPC you created (e.g., "Mattermost-VPC").
- **Availability Zones and Subnets**: Ensure you select the correct **public** subnets with internet gateway routes. Amazon selects the private ones by default. If you receive the notice that "The selected subnet does not have a route to an internet gateway," you may have selected the private subnet.
- Attach the security group created for the ALB (`Mattermost-ALB-SG`).
- **Listeners**: Add a listener for HTTP (80). Optionally, add a listener for HTTPS (443) and configure SSL settings.
- **Default Action**: Select the existing target group `Mattermost-Targets`.
- **Default SSL/TLS server certificate**:
    - **Certificate source**: Certificate (from ACM).
    - **Certificate (from ACM)**: Select the certificate for your domain we created earlier.
- The AWS Global Accelerator can be enabled to improve performance and availability.
    - Accelerator name: `Mattermost-ALB-GA`.
- Review the settings and click "Create Load Balancer".

## Database Configuration

### 7. Provision the PostgreSQL Database

#### Create an RDS PostgreSQL Instance

For best performance, Amazon AuroraDB will be used to host the database.

- Go to the RDS service and click "Create database".
- **Database Creation Method**: Choose "Standard Create".
- **Engine Options**: Select "Aurora (PostgreSQL Compatible)".
- **Engine version**: "Default for major version 16" or latest default.
- **Templates**: Choose "Production".
- **DB Instance Identifier**: Enter a name (e.g., `MattermostDB`).
- **Master Username**: `mmuser`
- **Credentials management**: Self Managed
- **Master Password**: `StrongPassword`
    - [1password Password Generator](https://1password.com/password-generator/)
    - **Password Guidelines**
        - The password in the connection string should be chosen carefully to prevent connection issues. Here are some key considerations:
            - **Avoid Special Characters**: Some special characters can cause issues if not properly encoded or escaped. Characters such as :, @, /, ?, #, &, and = should generally be avoided in passwords.
            - If these characters must be used, they need to be **URL-encoded**. For example, @ becomes %40.
            - **No Spaces**: Avoid using spaces in the password, as they can break the connection string parsing.
            - Length and Complexity: **Use a strong password** that is long enough and includes a mix of uppercase and lowercase letters, numbers, and other special characters that do not conflict with URL encoding (e.g., !, $, _).
            - **Escape Sequences**: Ensure special characters are correctly escaped in the connection string. URL-encoding tools can help with this.
- **Cluster storage configuration**: Aurora I/O-Optimized
- **DB Instance Class**: Select an instance type (e.g., `db.r6i.large`).
- **Multi-AZ deployment**: Create an Aurora Replica or Reader node in a different AZ
- **Compute resource**: Don’t connect to an EC2 compute resource.
- **Network type**: IPv4
- **Virtual private cloud (VPC)**: Choose the VPC created earlier (Eg. `Mattermost-VPC`)
- **DB subnet group**: Create new
- **Public access**: No
- **VPC security group**: Choose the DB security group created earlier (Eg. ``Mattermost-DB-SG`)
- **Multi-AZ Deployment**: Enable for high availability.
- **VPC and Subnets**: Select the VPC and private subnets created earlier.
- **Security Groups**: Attach the security group created for RDS (`Mattermost-DB-SG`).
- **Performance Insights**: Enable performance monitoring.

## Application Configuration

### 8. Set Up the Application Nodes

#### Launch EC2 Instances

- Go to the EC2 service and launch instances using Amazon Linux.
- **Name**: `Mattermost-App`
- **Instance Type**: Choose based on the expected load (e.g., `m5.large`).
- **Network Settings**: Edit and select the VPC and private subnets created earlier.
- **Security Groups**: Attach the security group created for the EC2 instances (`Mattermost-App-SG`).
- Configure Storage: `30GiB` minimum root volume.
- **Advanced details, Hostname type**: Resource name
- **Summary, Number of instances**: `2`
- Click "Launch instance."
- After the instances are created, rename them to `Mattermost-App-01` and `Mattermost-App-02`

#### Update Load Balancer Target Groups

- Go to the EC2 dashboard and select "Target Groups" under "Load Balancing".
- Click on the Mattermost Target group (Eg. `Mattermost-Targets`).
- Click "Register targets"
- Select the two EC2 Instances created earlier, ensure `8065` is selected for the port and click "Include as pending below"
- Click "Register pending targets"
- On the **Group details** tab, in the **Attributes** section, choose **Edit**.
- On the **Edit attributes** page, do the following:
    - Select **Stickiness**, Turn on stickiness.
    - **Stickiness type**: Application-based cookie
    - **Stickiness duration**: 12 Hours
    - **App cookie name**: `MMCSRF`
    - Choose **Save changes**.

### 9. Install Mattermost

#### Create Mattermost Database

##### Install Dependencies

- Using the EC2 Instance Connect Endpoint, SSH (`aws ec2-instance-connect ssh --instance-id <ID>`) into each EC2 instance and run the following commands:

 ```bash
 sudo dnf update -y && sudo dnf install postgresql15
 ```

##### Connect to PostgreSQL

- Go to the RDS Dashboard and select your `mattermost` database.
- Under "Endpoints" there should be two listed. One for the writer and the other for the reader. Make a note of both endpoints as they will be needed in the configuration later. Note that the reader instance includes an `ro` in the url.
    - Writer = `mattermostdb.cluster-<ID>.<ZONE>.rds.amazonaws.com`
    - Reader = `mattermostdb.cluster-ro-<ID>.<ZONE>.rds.amazonaws.com`

 ```bash
 psql --host=<WRITER_ENDPOINT> --port=5432 --dbname=postgres --username=mmuser
 ```

##### Create the Database

- Run the command below to create the database then quit with `\q`

 ```sql
 CREATE DATABASE mattermost WITH ENCODING 'UTF8' LC_COLLATE='en_US.UTF-8' LC_CTYPE='en_US.UTF-8' TEMPLATE=template0;
 ```

##### Download and Extract Mattermost

On each node, complete the following:

- Download the Mattermost tarball:
    - Update the `VERSION` below with the latest ESR release from the [version archive](https://docs.mattermost.com/about/version-archive.html).

  ```bash
  export VERSION=9.5.8 && wget https://releases.mattermost.com/$VERSION/mattermost-$VERSION-linux-amd64.tar.gz
  ```

- Extract the tarball:

  ```bash
  tar -xvzf mattermost-$VERSION-linux-amd64.tar.gz
  sudo mv mattermost /opt
  sudo mkdir /opt/mattermost/data
  ```

##### Create a Mattermost User

- Add a Mattermost user and set the proper permissions:

  ```bash
  sudo useradd --system --user-group mattermost
  sudo chown -R mattermost:mattermost /opt/mattermost
  sudo chmod -R g+w /opt/mattermost
  ```

##### Configure Mattermost

- Edit the `config.json` file to set up the database connection and other settings:

  ```bash
  sudo nano /opt/mattermost/config/config.json
  ```

- Update the settings as required, particularly the database settings. The `DataSource` is the **writer** endpoint and the `DataSourceReplicas` is the **reader**.

 ```json
 "DriverName": "postgres",
 "DataSource": "postgres://mmuser:<PASSWORD>@mattermostdb.cluster-<ID>.<ZONE>.rds.amazonaws.com/mattermost?sslmode=disable&connect_timeout=10",
 "DataSourceReplicas": ["postgres://mmuser:<PASSWORD>@mattermostdb.cluster-ro-<ID>.<ZONE>.rds.amazonaws.com/mattermost?sslmode=disable&connect_timeout=10"],
 ```

- Set `ServiceSettings.EnableLocalMode` to true to allow `mmctl` commands.
- (Optionally) Set `PluginSettings.EnableUploads` to true.

##### Create Systemd Service

- Create a systemd service file for Mattermost:

  ```bash
  sudo nano /lib/systemd/system/mattermost.service
  ```

- Add the following content:

  ```cfg
  [Unit]
  Description=Mattermost
  After=network.target

  [Service]
  Type=simple
  User=mattermost
  ExecStart=/opt/mattermost/bin/mattermost
  WorkingDirectory=/opt/mattermost
  Restart=always
  RestartSec=10
  LimitNOFILE=49152

  [Install]
  WantedBy=multi-user.target
  ```

- Reload systemd and start the Mattermost service:

  ```bash
  sudo systemctl daemon-reload
  sudo systemctl enable mattermost
  sudo systemctl start mattermost
  ```

## Initial Mattermost Configuration

### 10. Create an Admin Account

Once Mattermost is installed and running on both nodes, you must create the first admin account. Navigate to the EC2 dashboard and select "**Load Balancers**" under "Load Balancing". Select the load balancer created earlier to view its properties. On this screen, you will see the load balancer "**DNS name**" (`Mattermost-ALB-<ID>.<ZONE>.elb.amazonaws.com`). You can connect to this directly to set up your account, but it should now be added to your domain's DNS as a `CNAME` matching your `SiteURL`.

- Connect to your `SiteURL` through the Load Balancer, and Mattermost should load the initial account creation screen.
- Create your Admin account and the initial team.

### 11. Cluster Configuration

- Now that the admin account is created and Mattermost is running, update the config file on both nodes to enable the cluster.

```bash
sudo nano /opt/mattermost/config/config.json
```

- Search the config file for `ClusterSettings` and edit the values to enable the cluster.
- Change `Enable` to `true` and set `ClusterName` to `Production`. The default settings are shown below:

```json
    "ClusterSettings": {
        "Enable": true,
        "ClusterName": "Production",
        "OverrideHostname": "",
        "NetworkInterface": "",
        "BindAddress": "",
        "AdvertiseAddress": "",
        "UseIPAddress": true,
        "EnableGossipCompression": true,
        "EnableExperimentalGossipEncryption": false,
        "ReadOnlyConfig": true,
        "GossipPort": 8074,
        "StreamingPort": 8075,
        "MaxIdleConns": 100,
        "MaxIdleConnsPerHost": 128,
        "IdleConnTimeoutMilliseconds": 90000
    },
```

- Ensure the config file is the same on both nodes, and then restart the service on both. `sudo systemctl restart mattermost`.
- Login to the Mattermost System Console and ensure the cluster status is appearing as expected and the nodes find themselves. `<SiteURL>/admin_console/environment/high_availability`

### 12. Move configuration to the Database

When configuration in the database is enabled, any changes to the configuration are recorded to the `Configurations` and `ConfigurationFiles` tables and `ClusterSettings.ReadOnlyConfig` is ignored, enabling full use of the System Console.

- Review your `/opt/mattermost/config/config.json` file for the database connection string.
    - `cat /opt/mattermost/config/config.json | grep "DataSource"`
- Create an environment file on both nodes to store the database connection string.

```bash
sudo nano /opt/mattermost/config/mattermost.environment
```

- Add your connection string to the variable below and then add to the top of the `mattermost.environment` file.
    - If you have `\u0026` in the connection string, replace it with `&`, or the service will fail to start.

```bash
MM_CONFIG='postgres://mmuser:<PASSWORD>@mattermostdb.cluster-<ID>.<ZONE>.rds.amazonaws.com/mattermost?sslmode=disable&connect_timeout=10'
```

- Edit the `mattermost.service` file to load the environment file.

```bash
sudo nano /lib/systemd/system/mattermost.service
```

- Add the following under `[Service]` just above `ExecStart`:

```bash
EnvironmentFile=/opt/mattermost/config/mattermost.environment
```

- Migrate the config to the database using `mmctl`. This process only needs to be completed on one node.
    - *Ensure the `--local` is included in your `mmct` command.*
    - `?sslmode=disable&connect_timeout=10` is not supported here and may cause the `mmctl` command to fail.

```bash
/opt/mattermost/bin/mmctl config migrate /opt/mattermost/config/config.json "postgres://mmuser:<PASSWORD>@mattermostdb.cluster-<ID>.<ZONE>.rds.amazonaws.com/mattermost" --local
```

- Once the configuration is migrated to the database, reload the `mattermost.service` on each node to load the new configuration.

```bash
sudo systemctl daemon-reload
sudo systemctl restart mattermost
```

### 13. Configure S3 Storage for Mattermost

To configure Amazon S3 for Mattermost file storage, including files, plugins, and other data, follow these detailed steps:

#### Create an S3 Bucket

1. **Navigate to the S3 Service**:
      - Open the AWS Management Console.
      - Select "S3" under "Storage".

2. **Create a New Bucket**:
      - Click on "Create bucket".
      - **Bucket name**: Enter a globally unique name (e.g., `mattermost-files-storage`).
      - **Region**: Choose the same region as your Mattermost deployment for optimal performance.

3. **Configure Bucket Settings**:
      - **Object Ownership**: Choose "ACLs disabled".
      - **Block Public Access settings for this bucket**: Ensure all public access is blocked for security.
      - **Bucket Versioning**: Enable versioning if you want to keep multiple versions of an object (useful for backup purposes).
      - **Tags**: Add tags for resource management, e.g., `Environment=Production`.
      - **Default encryption**: Server-side encryption with Amazon S3 managed keys (SSE-S3)

4. **Review and Create Bucket**:
      - Review the settings and click "Create bucket".

#### Set Up Bucket Permissions

You can use IAM roles and a corresponding bucket policy to allow the app nodes to access the S3 bucket. Here’s how you can set this up:

##### Create IAM Roles for EC2 Instances

1. **Create IAM Roles**:
      - Go to the IAM service in the AWS Management Console and create a new role.
      - Choose **AWS service** as the type of trusted entity and select **EC2**.
      - Attach the policy `AmazonS3FullAccess` or a custom policy that grants the necessary permissions for S3 access.
      - Name the role (e.g., `MattermostS3AccessRole`).

2. **Attach the Role to EC2 Instances**:
      - Go to the EC2 Dashboard, select your instances, and choose **Actions** > **Security** > **Modify IAM Role**.
      - Attach the created IAM role (`MattermostS3AccessRole`) to each instance.

##### Set Up the S3 Bucket Policy

The bucket policy will grant the IAM role attached to the EC2 instances permissions to access the S3 bucket. Here's an example policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::<account-id>:role/MattermostS3AccessRole"
        ]
      },
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::mattermost-files-storage",
        "arn:aws:s3:::mattermost-files-storage/*"
      ]
    }
  ]
}
```

###### Policy Explanations

- **Version**: Specifies the version of the policy language.
- **Statement**: Contains the policy's permission statements.
- **Effect**: Set to `"Allow"` to permit access.
- **Principal**: Identifies the AWS account, user, role, or federated user to which the policy is attached.
    - Replace `<account-id>` with your AWS account ID.
    - `"arn:aws:iam::<account-id>:role/MattermostS3AccessRole"` specifies the IAM role that has permissions.
- **Action**: Specify the S3 actions allowed, e.g., `s3:*` for all actions.
- **Resource**: Specifies the S3 bucket and objects the permissions apply to.
    - `"arn:aws:s3:::mattermost-files-storage"` is the bucket itself.
    - `"arn:aws:s3:::mattermost-files-storage/*"` covers all objects within the bucket.

#### Apply the Bucket Policy

1. **Navigate to the S3 Service**:
      - In the AWS Management Console, go to the S3 service.
      - Select the bucket for which you want to set permissions (`mattermost-files-storage`).

2. **Edit the Bucket Policy**:
      - Go to the **Permissions** tab and select **Bucket Policy**.
      - Paste the JSON policy above into the policy editor, replacing placeholders with actual values.
      - Save the changes.

#### Configure Mattermost to Use S3

1. **Edit Mattermost Configuration**:
      - SSH into your Mattermost application server.
      - Edit the `config.json` file located in `/opt/mattermost/config/config.json`.

2. **Set Up S3 Configuration**:
      - Update the `FileSettings` section with your S3 bucket details.
        - Ensure to replace `<bucket-region>` with your AWS region, `AmazonS3Bucket` with `mattermost-files-storage` and `DriverName` with `amazons3`.
      - Default values are shown below:

     ```json
     "FileSettings": {
       "DriverName": "amazons3",
       "AmazonS3AccessKeyId": "<your-access-key>",
       "AmazonS3SecretAccessKey": "<your-secret-key>",
       "AmazonS3Bucket": "mattermost-files-storage",
       "AmazonS3PathPrefix": "",
       "AmazonS3Region": "<bucket-region>",
       "AmazonS3Endpoint": "",
       "AmazonS3SSL": true,
       "AmazonS3SignV2": false,
       "AmazonS3SSE": false,
       "AmazonS3Trace": false
     }
     ```

3. **Restart Mattermost**:
      - Restart the Mattermost service to apply the changes:

     ```bash
     sudo systemctl restart mattermost
     ```

#### Test and Validation

- Log in to Mattermost and upload a file to test the S3 integration.
- Ensure that files are being stored in the specified S3 bucket.

### 14. Setup and Configure LDAP/SAML/SSO

Configure your single sign-on solution if required in your environment. Mattermost supports using [LDAP and SAML to sync accounts and groups](https://docs.mattermost.com/onboard/sso-saml-ldapsync.html).

- **SAML**: [SAML Single Sign-On](https://docs.mattermost.com/onboard/sso-saml.html#saml-single-sign-on ) .
- **AD/LDAP**: [Active Directory/LDAP](https://docs.mattermost.com/onboard/ad-ldap.html#active-directory-ldap-setup).

## (Optional) Calls Setup

==Work in Progress ...==

## ElasticSearch Configuration

For more details, review the [Elasticsearch](https://docs.mattermost.com/scale/elasticsearch.html) product documentation.

### 1. Create and Configure ElasticSearch Cluster

==Work in Progress ...==

### 1. Configure Mattermost to use ElasticSearch

==Work in Progress ...==

## Monitoring, Logging, and Maintenance

For more details on installing and configuring Prometheus and Grafana, review [Deploy Prometheus and Grafana for performance monitoring](https://docs.mattermost.com/scale/deploy-prometheus-grafana-for-performance-monitoring.html) in the main product documentation.

### 1. Set Up Prometheus

==Work in Progress ...==

- Create a new EC2 instance for Prometheus.
- Install Prometheus and configure it to scrape metrics from Mattermost and PostgreSQL.

### 1. Set Up Grafana

==Work in Progress ...==

- Launch an EC2 instance for Grafana or use AWS Managed Grafana.
- Connect Grafana to Prometheus as a data source.
- Create dashboards to visualize metrics.
- Setup [Performance Alerts](https://docs.mattermost.com/scale/performance-alerting.html).

### 1. Integrate with CloudWatch

- Enable CloudWatch logging for EC2 and RDS instances.
- Configure CloudWatch Alarms for critical metrics.

## Backup, Recovery, and Updating

### 1. Automate Backups

- Enable automatic backups in RDS and set a retention period.
- Regularly test your backup and recovery process.

### 1. Regular Updates

Regularly update EC2 instances and Mattermost software.

- To update Mattermost on each node:

- Download the Mattermost tarball:
    - Update the `VERSION` below with the latest ESR release from the [version archive](https://docs.mattermost.com/about/version-archive.html).

  ```bash
  export VERSION=9.5.8 && wget https://releases.mattermost.com/$VERSION/mattermost-$VERSION-linux-amd64.tar.gz
  ```

- Extract the tarball:

  ```bash
  tar -xvzf mattermost-$VERSION-linux-amd64.tar.gz
  ```

- Shutdown Mattermost, update files, and restart Mattermost:

  ```bash
  sudo systemctl stop mattermost.service
  sudo mv mattermost /opt
  sudo chown -R mattermost:mattermost /opt/mattermost
  sudo chmod -R g+w /opt/mattermost
  sudo systemctl start mattermost.service
  ```
