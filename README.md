# Mattermost Customer Success Technical Guides

## DEV Docker Usage

### Serve DEV Docs on 8000

```bash
docker run -v $(pwd):/mnt -p 8000:8000 --rm --name cs-docs ghcr.io/maxwellpower/mm-cs-deploy-docs
```

- Run in backround

```bash
docker run -v $(pwd):/mnt -p 8000:8000 --rm --name cs-docs -d ghcr.io/maxwellpower/mm-cs-deploy-docs
```

### Markdown Lint

```bash
docker run -v $(pwd):/mnt --rm --entrypoint "markdownlint" ghcr.io/maxwellpower/mm-cs-deploy-docs .
```

## Local Build

```bash
docker build . --tag ghcr.io/maxwellpower/mm-cs-deploy-docs
 ```
