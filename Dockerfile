ARG IMAGE
ARG TAG
ARG CLI_VERSION=latest

FROM ${IMAGE} as parent
ENV MAVEN_CONFIG="" \
    SNYK_INTEGRATION_NAME="DOCKER_SNYK" \
    SNYK_INTEGRATION_VERSION=${TAG} \
    SNYK_CFG_DISABLESUGGESTIONS=true \
    SNYK_CLI_VERSION=${CLI_VERSION}
WORKDIR /app
COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["snyk", "test"]


FROM ubuntu as snyk
ARG CLI_VERSION
ENV SNYK_CLI_VERSION=$CLI_VERSION
RUN echo "SNYK_CLI_VERSION=${SNYK_CLI_VERSION}"

RUN apt-get update && apt-get install -y curl python3 python3-requests
RUN curl --compressed --output /usr/local/bin/install-snyk.py https://raw.githubusercontent.com/snyk/cli/main/scripts/install-snyk.py
RUN chmod +x /usr/local/bin/install-snyk.py
RUN install-snyk.py $SNYK_CLI_VERSION

FROM alpine as snyk-alpine
ARG CLI_VERSION
ENV SNYK_CLI_VERSION=$CLI_VERSION
RUN echo "SNYK_CLI_VERSION=${SNYK_CLI_VERSION}"

RUN apk update && apk add --no-cache git curl python3 py3-requests
RUN curl --compressed --output /usr/local/bin/install-snyk.py https://raw.githubusercontent.com/snyk/cli/main/scripts/install-snyk.py
RUN chmod +x /usr/local/bin/install-snyk.py
RUN install-snyk.py $SNYK_CLI_VERSION

FROM parent as alpine
RUN apk update && apk upgrade --no-cache
RUN apk add --no-cache libstdc++ git
COPY --from=snyk-alpine ./snyk /usr/local/bin/snyk

FROM parent as linux
COPY --from=snyk ./snyk /usr/local/bin/snyk
RUN apt-get update && apt-get install -y \
    ca-certificates \
    git \
    && apt-get auto-remove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
