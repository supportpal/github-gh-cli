FROM debian:buster-slim

RUN apt-get update ; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
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

ENV GITHUB_CLI_VERSION 1.10.0

RUN echo "deb https://cli.github.com/packages buster main" > /etc/apt/sources.list.d/github-cli.list

RUN apt-get update; \
	apt-get install -y gh="${GITHUB_CLI_VERSION}"; \
	rm -rf /var/lib/apt/lists/* \

CMD ["gh"]
