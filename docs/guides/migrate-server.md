# Migrating Mattermost from One OS to Another

## Pre-Migration Preparation

1. Verify Current Setup:

    - Note the current Mattermost version (e.g., Enterprise Edition or Team Edition).
    - Confirm the PostgreSQL database version and location (on the same host or remote).

2. Prepare the New Server:

    - Install the same version of Mattermost on the new server.
    - Ensure the new server meets all Mattermost system requirements:
        - Supported OS
        - Sufficient hardware resources
        - Compatible database and libraries.
    - Set up the PostgreSQL database server (if the database is hosted on the same machine).

3. Networking and Access:

    - Confirm the new server's hostname and IP address.
    - Open necessary ports (e.g., 8065 for Mattermost and database-specific ports).
    - Configure the new server with appropriate DNS entries and SSL/TLS certificates.

4. Backup the Existing Instance:

    - Create a complete backup of Mattermost data:
        - Files and folders (`/opt/mattermost` or equivalent installation directory).
        - PostgreSQL database:

            ```bash
            pg_dump -U <username> -h <host> -d <database> -F c -b -v -f mattermost_backup.dump
            ```

        - Replace `<username>`, `<host>`, and `<database>` with appropriate values.
    - Store backups in a secure location.

## Migration Process

### Scenario 1: Database Hosted on the Same Server

1. Migrate Database:

    - Copy the database dump file (`mattermost_backup.dump`) to the new server.
    - Restore the database on the new server:

        ```bash
        pg_restore -U <username> -h localhost -d <new_database> -v mattermost_backup.dump
        ```

2. Migrate Mattermost Files:

    - Compress the Mattermost installation folder:

        ```bash
        tar -czvf mattermost.tar.gz /opt/mattermost
        ```

    - Transfer the archive to the new server and extract it:

        ```bash
        tar -xzvf mattermost.tar.gz -C /opt/
        ```

3. Update Configuration:

    - Edit `config.json` in the Mattermost directory to reflect the new server's hostname, IP address, and database details.

4. Start Mattermost:

    - Restart the Mattermost service:

        ```bash
        systemctl start mattermost
        ```

5. Test the Instance:

    - Verify functionality (e.g., user access, team data, integrations).

### Scenario 2: Database Hosted Remotely

1. Update Database Access:

    - Ensure the new server can access the remote PostgreSQL database.
    - Update `config.json` with the correct database hostname and credentials.

2. Migrate Mattermost Files:

    - Follow the steps in **Scenario 1** to transfer and configure Mattermost files.

3. Start and Test:

    - Restart the Mattermost service and validate functionality.

## Post-Migration Steps

1. Testing:

    - Test critical features such as user authentication (e.g., Active Directory integration), messaging, and file uploads.

2. DNS and SSL Configuration:

    - Update DNS entries to point to the new server.
    - Verify SSL/TLS certificates are correctly configured.

3. Monitor Performance:

    - Monitor logs (`/opt/mattermost/logs`) for errors.
    - Test load performance if applicable.

4. Retain Backup for Rollback:

    - Keep backups available until the new instance is stable.
