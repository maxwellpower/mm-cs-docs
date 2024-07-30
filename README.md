# Mattermost Customer Success Technical Guides

This project is intended to document and share processes developed and supported by the Mattermost Customer Success Team.

> [!WARNING]
> These guides may not be complete or fit for purpose and should be used in consultation with the Mattermost Customer Success Team.

Documentation in `/docs` is published using GitHub pages and is availabe at [mmcs.maxpower.dev](https://mmcs.maxpower.dev).

Review the [**Mattermost Product Documentation**](https://docs.mattermost.com/guides/deployment.html) for additional information.

## 🚀 **Elevate Your Team with Mattermost Academy!** 🚀

**Unleash the full potential of collaboration** with exclusive courses, hot topics, and expert guidance - all in one place.

🔗 Join the excitement at [academy.mattermost.com](https://academy.mattermost.com/)!

---

## Development Docker Image

This project includes a Docker image that can be used to preview the docs during development. Usage assumes the repository is cloned locally.

### Serve docs on port `8000`

```bash
docker run -v $(pwd):/mnt -p 8000:8000 --rm --name cs-docs ghcr.io/maxwellpower/mm-cs-docs
```

#### Run in backround

```bash
docker run -v $(pwd):/mnt -p 8000:8000 --rm --name cs-docs -d ghcr.io/maxwellpower/mm-cs-docs
```

### Build and save docs to `/public`

```bash
docker run -v $(pwd):/mnt -p 8000:8000 --rm --name cs-docs ghcr.io/maxwellpower/mm-cs-docs build
```

### Run Markdown Linting

```bash
docker run -v $(pwd):/mnt --rm --entrypoint "markdownlint" ghcr.io/maxwellpower/mm-cs-docs .
```

### Build the Image

```bash
docker build . --tag ghcr.io/maxwellpower/mm-cs-docs
 ```
