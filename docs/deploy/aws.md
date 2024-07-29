# Deploying Mattermost Enterprise High-Availability via AWS

A Step-by-Step Guide to Create and Configure a VPC, Security Groups, ALB, Database, and Application Nodes for Mattermost on AWS

## Network Resources

### 1. Create a VPC

#### Step 1: Navigate to the VPC Dashboard

- Go to the AWS Management Console.
- Open the VPC Dashboard by selecting "**VPC**" under the "**Networking & Content Delivery**" section.

#### Step 2: Create VPC Settings

- **VPC and More**: Ensure "**VPC and More**" is selected to create the VPC with subnets, route tables, and other networking resources.
- **Name Tag Auto-Generation**: Check "**Auto-generate**" to have AWS automatically generate name tags for the VPC components.
- **Name Tag**: Enter a name for your VPC (e.g., `Mattermost-VPC`).
- **IPv4 CIDR Block**: Specify an IPv4 CIDR block for the VPC (e.g., `10.0.0.0/16`).
- **IPv6 CIDR Block**: If not required, select "No IPv6 CIDR Block".
- **Tenancy**: Select "Default" unless dedicated tenancy is required.

#### Step 3: Subnet Configuration

- **Number of Availability Zones (AZs)**: Choose `2` for high availability.
- **Number of Public Subnets**: Set to `2` for redundancy across multiple AZs.
- **Number of Private Subnets**: Set to `2` for redundancy across multiple AZs.

#### Step 4: Customize Subnet CIDR Blocks (if necessary)

- **Public Subnets**:
  - Subnet 1 (us-west-1b): `10.0.0.0/24`
  - Subnet 2 (us-west-1c): `10.0.1.0/24`
- **Private Subnets**:
  - Subnet 1 (us-west-1b): `10.0.2.0/24`
  - Subnet 2 (us-west-1c): `10.0.3.0/24`

#### Step 5: NAT Gateways

- Select "**1 NAT Gateway per AZ**" for fault tolerance and to allow private subnets to access the internet for updates and patching.

#### Step 6: VPC Endpoints

- **Gateway Endpoints**: Consider enabling endpoints for services like S3 for improved performance and security.

#### Step 7: DNS Options

- Enable "**Enable DNS hostnames**" and "**Enable DNS resolution**" to use DNS within your VPC.

#### Step 8: Additional Tags

- Add tags as needed for resource management and billing.

#### Step 9: Create VPC

- Review the settings and click "Create VPC".

### 2. Set Up Security Groups

#### Step 1: Create a Security Group for the Load Balancer

- Go to the EC2 Dashboard.
- Select "Security Groups" under "Network & Security" from the left-hand menu.
- Click "Create security group".
- **Name**: Enter a name (e.g., `Mattermost-ALB-SG`).
- **Description**: Provide a description (e.g., "Security group for Mattermost ALB").
- **VPC**: Select the VPC you created (e.g., "Mattermost-VPC").
- **Inbound Rules**: Add rules to allow HTTP (port 80) and HTTPS (port 443) traffic from anywhere (0.0.0.0/0).
- **Outbound Rules**: Allow all outbound traffic.

#### Step 2: Create a Security Group for the Database

- Go to "**Security Groups**" and click "**Create security group**".
- **Name**: Enter a name (e.g., `Mattermost-DB-SG`).
- **Description**: Provide a description (e.g., "Security group for Mattermost database").
- **VPC**: Select the VPC you created.
- **Inbound Rules**: Allow `PostgreSQL` traffic (port 5432) from the application nodes security group.
- **Outbound Rules**: Allow all outbound traffic.

#### Step 3: Create a Security Group for the Application Nodes

- Go to "Security Groups" and click "Create security group".
- **Name**: Enter a name (e.g., `Mattermost-App-SG`).
- **Description**: Provide a description (e.g., "Security group for Mattermost application nodes").
- **VPC**: Select the VPC you created.
- **Inbound Rules**:
  - Allow `Custom TCP` (port 8065) from the ALB security group (`Mattermost-ALB-SG`).
  - Allow `PostgreSQL` (port 5432) from the DB security group (`Mattermost-DB-SG`)
  - Allow `SSH` traffic (port 22) from your IP address for management.
  - Allow `ALL` Traffic from within the security group (`Mattermost-App-SG`).
- **Outbound Rules**: Allow all outbound traffic.

### 3. Create VPC Endpoint
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
	If you are using SSL/TLS, ensure that the certificate we generated earlier is "**Issued**," or it will not be available to be selected. Once the DNS records are updated, certificates can take 30 minutes to validate.

#### Step 1: Create an Application Load Balancer (ALB)

- Go to the EC2 service and select "Load Balancers" under "Load Balancing".
- Click "Create Load Balancer" and select "Application Load Balancer".
- **Basic Configuration**:
  - **Load Balancer Name**: Enter a name for the ALB (e.g., `Mattermost-ALB`).
  - **Scheme**: Choose "internet-facing".
  - **IP Address Type**: Select "IPv4".

#### Step 2: Network Mapping

- **VPC**: Select the VPC you created (e.g., "Mattermost-VPC").
- **Availability Zones and Subnets**: Ensure you select the correct **public** subnets with internet gateway routes. Amazon selects the private ones by default. If you receive the notice that "The selected subnet does not have a route to an internet gateway," you may have selected the private subnet.

#### Step 3: Security Groups

- Attach the security group created for the ALB (`Mattermost-ALB-SG`).

#### Step 4: Listeners and Routing

- **Listeners**: Add a listener for HTTP (80). Optionally, add a listener for HTTPS (443) and configure SSL settings.
- **Default Action**: Select the existing target group `Mattermost-Targets`.

#### Step 5: Secure Listener Settings

- **Default SSL/TLS server certificate**:
  - **Certificate source**: Certificate (from ACM).
  - **Certificate (from ACM)**: Select the certificate for your domain we created earlier.

#### Step 6: Optional Features

- The AWS Global Accelerator can be enabled to improve performance and availability.
  - Accelerator name: `Mattermost-ALB-GA`.

#### Step 7: Create Load Balancer

- Review the settings and click "Create Load Balancer".

## Database Configuration

### 6. Provision the PostgreSQL Database

#### Step 1: Create an RDS PostgreSQL Instance

- Go to the RDS service and click "Create database".
- **Database Creation Method**: Choose "Standard Create".
- **Engine Options**: Select "Aurora (PostgreSQL Compatible)".
- **Engine version**: "Default for major version 16" or latest default.
- **Templates**: Choose "Production".
- **DB Instance Identifier**: Enter a name (e.g., `MattermostDB`).
- **Master Username**: `mmuser`
- **Credentials management**: Self Managed
- **Master Password**: `StrongPassword`
	- [1password Generator](https://1password.com/password-generator/)
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

### 7. Set Up the Application Nodes

#### Step 1: Launch EC2 Instances

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

#### Step 2: Update Target Groups

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

#### Step 2: Create Mattermost Database

##### Install Dependencies

- Using the EC2 Instance Connect Endpoint, SSH (`aws ec2-instance-connect ssh --instance-id <ID>`) into each EC2 instance and run the following commands:

	```bash
	sudo dnf update -y && sudo dnf install postgresql15
	```

##### Connect to PostgreSQL

- Go to the RDS Dashboard and select your `mattermost` database.
- Under "Endpoints" there should be two listed. One for the writer and the other for the reader. Make a note of both endpoints as they will be needed in the configuration later.
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

#### Step 3: Install Mattermost

##### Download and Extract Mattermost

Update the version below with the latest ESR release from the [version archive](https://docs.mattermost.com/about/version-archive.html).

- Download the Mattermost tarball:
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

##### Create Systemd Service

- Create a systemd service file for Mattermost:
  ```bash
  sudo nano /etc/systemd/system/mattermost.service
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

## Initial Configuration

### 8. Create an Admin Account

Once Mattermost is installed and running on both nodes, you must create the first admin account. Navigate to the EC2 dashboard and select "**Load Balancers**" under "Load Balancing". Select the load balancer created earlier to view its properties. On this screen, you will see the load balancer "**DNS name**" (`Mattermost-ALB-<ID>.<ZONE>.elb.amazonaws.com`). You can connect to this directly to set up your account, but it should now be added to your domain's DNS as a `CNAME` matching your `SiteURL`.

- Connect to your `SiteURL` through the Load Balancer, and Mattermost should load the initial account creation screen.
- Create your Admin account and the initial team.

### 9. Cluster Configuration

- Now that the admin account is created and Mattermost is running, update the config file on both nodes to enable the cluster.

```bash
sudo nano /opt/mattermost/config/config.json
```

- Search the config file for `ClusterSettings` and edit the values to enable the cluster.

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

### 10. Move configuration to the Database

When configuration in the database is enabled, any changes to the configuration are recorded to the `Configurations` and `ConfigurationFiles` tables and `ClusterSettings.ReadOnlyConfig` is ignored, enabling full use of the System Console.

- Review your `/opt/mattermost/config/config.json` file for the database connection string.
- Create an environment file on both nodes to store the database connection string.

```bash
sudo nano /opt/mattermost/config/mattermost.environment
```

- Add your connection string to the variable below and then add to the top of the `mattermost.environment` file.

```text
MM_CONFIG='postgres://mmuser:<PASSWORD>@mattermostdb.cluster-<ID>.<ZONE>.rds.amazonaws.com/mattermost?sslmode=disable&connect_timeout=10'`
```

- Edit the `mattermost.service` file to load the environment file.

```bash
sudo nano /etc/systemd/system/mattermost.service
```

- Add the following under `[Service]` just above `ExecStart`:

```text
EnvironmentFile=/opt/mattermost/config/mattermost.environment
```

- Migrate the config to the database using `mmctl`. This process only needs to be completed on one node.

```bash
mmctl config migrate /opt/mattermost/config/config.json "postgres://mmuser:<PASSWORD>@mattermostdb.cluster-<ID>.<ZONE>.rds.amazonaws.com/mattermost?sslmode=disable&connect_timeout=10" --local
```

- Once the config is migrated to the Database, reload the `mattermost.service` to load the new configuration.

```bash
sudo systemctl daemon-reload
sudo systemctl restart mattermost
```

### 11. Setup and Configure LDAP/SAML/SSO

If required in your environment, configure your single sign on solution and/or LDAP.

- For SAML, review the [SAML Single Sign-On](https://docs.mattermost.com/onboard/sso-saml.html#saml-single-sign-on ) guide for more details.
- For LDAP, review the [Active directory/LDAP setup](https://docs.mattermost.com/onboard/ad-ldap.html#active-directory-ldap-setup) guide for more details.

## Monitoring and Maintenance

### 12. Monitoring and Logging

#### Step 1: Set Up Prometheus

- Create a new EC2 instance for Prometheus.
- Install Prometheus and configure it to scrape metrics from Mattermost and PostgreSQL.

#### Step 2: Set Up Grafana

- Launch an EC2 instance for Grafana or use AWS Managed Grafana.
- Connect Grafana to Prometheus as a data source.
- Create dashboards to visualize metrics.

#### Step 3: Integrate with CloudWatch

- Enable CloudWatch logging for EC2 and RDS instances.
- Configure CloudWatch Alarms for critical metrics.

### 13. Backup and Recovery

#### Step 1: Automate Backups

- Enable automatic backups in RDS and set a retention period.
- Regularly test your backup and recovery process.

### 14. Security Best Practices

#### Step 1: Regular Updates

- Regularly update EC2 instances and Mattermost software.
- Implement IAM roles and policies following the principle of least privilege.
- Ensure all communications are encrypted using HTTPS.
