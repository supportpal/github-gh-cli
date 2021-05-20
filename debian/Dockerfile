FROM debian:buster-slim

RUN set -ex; \
    apt-get update ; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        dirmngr; \
    rm -rf /var/lib/apt/lists/*

RUN set -ex; \
	key='2CA32056ED206CB81F44A8CAC99B11DEB97541F0'; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
	gpg --batch --export "$key" > /etc/apt/trusted.gpg.d/github.gpg; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME"; \
	apt-key list > /dev/null

ENV GITHUB_CLI_VERSION 1.10.0-pre.3

RUN set -ex; \
    curl -Ls "https://github.com/cli/cli/releases/download/v${GITHUB_CLI_VERSION}/gh_${GITHUB_CLI_VERSION}_linux_386.deb" -o gh.deb; \
	dpkg -i gh.deb; \
	rm -rf gh.deb \

CMD ["gh"]
