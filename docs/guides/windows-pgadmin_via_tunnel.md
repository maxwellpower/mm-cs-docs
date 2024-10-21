# Guide: Accessing Your Mattermost PostgreSQL Database via SSH Tunnel and pgAdmin

## Prerequisites

Before you start, please ensure you have the following:

1. **VS Code installed** on your Windows machine.
2. **SSH access to the server** where your Mattermost PostgreSQL database is hosted.
3. **pgAdmin installed** on your Windows machine. You can download it from [pgAdmin's official site](https://www.pgadmin.org/download/).

This guide will walk you through the process of:

1. Setting up an SSH tunnel using VS Code.
2. Installing and configuring pgAdmin to connect through the tunnel.

## Step 1: Establish an SSH Tunnel with VS Code

1. **Open VS Code** on your Windows machine.
2. **Open the integrated terminal** by clicking `Terminal > New Terminal` or using the shortcut `Ctrl + `` (backtick).
3. **Check if you have SSH installed** by running:

   ```bash
   ssh -V
   ```

   If SSH is not installed, you may need to install it. (Refer to [this link](https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse) for installation instructions.)

4. **Set up the SSH Tunnel:**
   Use the following command to create an SSH tunnel. Replace `<username>`, `<remote-server-ip>`, `<db-host-ip>`, and `<db-port>` with your own details:

   ```bash
   ssh -L 5432:<db-host-ip>:<db-port> <username>@<remote-server-ip>
   ```

   - `5432` is the local port on your Windows machine that you will connect to via pgAdmin.
   - `<db-host-ip>` is the IP address or hostname of the database server (it could be `localhost` if it's on the same server as the SSH).
   - `<db-port>` is the port PostgreSQL is running on (usually `5432`).
   - `<remote-server-ip>` is the IP address or hostname of the server you are connecting to via SSH.

5. **Keep this terminal open**. The SSH tunnel will remain active as long as this terminal window is open.

## Step 2: Install pgAdmin (if not already installed)

1. **Download pgAdmin** from the [pgAdmin website](https://www.pgadmin.org/download/).
2. **Run the installer** and follow the instructions to complete the installation.

## Step 3: Configure pgAdmin to Connect via the SSH Tunnel

1. **Open pgAdmin** on your Windows machine.
2. **Create a New Server Connection:**
   - In the left panel, right-click on `Servers` and select `Create > Server`.
   - In the `General` tab, give your connection a name (e.g., `Mattermost DB`).

3. **Configure the Connection:**
   - Switch to the `Connection` tab.
     - **Host name/address:** `localhost`
     - **Port:** `5432` (or the local port you forwarded in your SSH command)
     - **Maintenance database:** `mattermost` (or the name of your Mattermost database)
     - **Username:** Your database username
     - **Password:** Your database password

4. **Save the Connection:**
   - Click `Save` to finalize the setup.

## Step 4: Test the Connection

1. **Expand the server node** in the left panel in pgAdmin.
2. **You should see your database** and be able to browse tables, run queries, and manage data as needed.
3. If you encounter any issues, double-check the following:
   - Ensure the SSH tunnel is still active in the VS Code terminal.
   - Verify that the host, port, username, and password are correct in your pgAdmin configuration.
   - Check firewall settings or any access rules on your server that might restrict connections.

---

## Troubleshooting Tips

1. **SSH Tunnel Not Connecting:**
   - Verify the `<username>@<remote-server-ip>` is correct and that you can SSH into the server without issues.
   - Make sure no other services are using port `5432` on your local machine.

2. **Cannot Connect to Database in pgAdmin:**
   - Ensure the SSH tunnel is still active.
   - Double-check your pgAdmin settings, ensuring `localhost` and `5432` are correct.
   - Make sure your database username and password are accurate.
