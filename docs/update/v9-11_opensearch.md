# Upgrade Guide: Mattermost v9.11 Opensearch Migration

**Important:** Review the release notes for all versions between your current version and v9.11. Follow these steps carefully to avoid disruptions.

## 1. Prerequisites

- **Backup Your System:** Create a full backup of your Mattermost server and database.
- **Review System Requirements:** Ensure your environment meets the requirements for v9.11.

## 2. Key Changes in v9.11

- **Elasticsearch/Opensearch Migration:**
    - Added support for Elasticsearch v8 and Opensearch.
    - AWS customers using Elasticsearch v7.10.x must migrate to AWS Opensearch.

## 3. Upgrade Steps

### Step 1: Upgrade to Mattermost v9.11

1. **Stop the Mattermost Server.**
2. **Perform the upgrade** using your preferred method (e.g., package manager, manual install).

### Step 2: Update Configuration

**For Single-Node Deployments (`config.json`):**

1. Open `config.json` after the upgrade.
2. Change `ElasticsearchSettings.Backend` to `"opensearch"` if migrating.

   ```json
   "ElasticsearchSettings": {
       "Backend": "opensearch"
   }
   ```

3. **Disable Compatibility Mode** in Opensearch settings.

**For Clustered Environments Using `mmctl`:**

1. Connect to your Mattermost instance with `mmctl`.
2. Run:

   ```bash
   mmctl config set ElasticsearchSettings.Backend opensearch
   ```

### Step 3: Restart the Mattermost Server

- Restart the server to apply the changes.

## 4. Additional Considerations

- **Opensearch Transition:** AWS or self-hosted users must update `ElasticsearchSettings.Backend` to `opensearch` and disable compatibility mode.
- **Pre-Upgrade Preparation:** These settings can only be configured **after upgrading** to v9.11.

## 5. Troubleshooting

- **Configuration Verification:**

  ```bash
  mmctl config get ElasticsearchSettings
  ```

For more detailed notes, visit [Mattermost Upgrade Notes](https://docs.mattermost.com/upgrade/important-upgrade-notes.html).
