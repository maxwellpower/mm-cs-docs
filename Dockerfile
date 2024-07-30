# Mattermost Customer Success Documentation

# Copyright (c) 2024 Maxwell Power
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom
# the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
# AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# File: Dockerfile

FROM debian:latest

LABEL MAINTAINER="maxwell.power@mattermost.com"
LABEL org.opencontainers.image.title="mm-cs-docs"
LABEL org.opencontainers.image.description="Mattermost CS Docs"
LABEL org.opencontainers.image.authors="Maxwell Power"
LABEL org.opencontainers.image.source="https://github.com/maxwellpower/mm-cs-docs"
LABEL org.opencontainers.image.licenses=MIT

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update -qq && \
    apt-get install -yqq --no-install-recommends \
        build-essential \
        python3 \
        python3-pip \
        python3-dev \
        nodejs \
        npm && \
    apt-get autoremove --purge -yqq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip install mkdocs --break-system-packages && \
    pip install mkdocs-material --break-system-packages && \
    pip install mkdocs-minify-plugin --break-system-packages

# Install markdownlint-cli globally
RUN npm install -g markdownlint-cli

# Set the working directory
WORKDIR /mnt

# Set the entry point and default command
ENTRYPOINT ["mkdocs"]
CMD ["serve", "-v", "-a", "0.0.0.0:8000"]

# Expose port 8000
EXPOSE 8000

# Healthcheck to ensure the service is running
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 CMD pgrep -f mkdocs || exit 1
