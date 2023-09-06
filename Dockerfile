ARG IMAGE
ARG TAG

FROM ${IMAGE} as parent
ENV MAVEN_CONFIG="" \
    SNYK_INTEGRATION_NAME="DOCKER_SNYK" \
    SNYK_INTEGRATION_VERSION=${TAG} \
    SNYK_CFG_DISABLESUGGESTIONS=true
WORKDIR /app
COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["snyk", "test"]


FROM ubuntu as snyk
RUN apt-get update  && apt-get install -y curl ca-certificates
RUN curl --compressed --retry 3 --retry-delay 60 -o ./snyk-linux https://static.snyk.io/cli/latest/snyk-linux && \
    curl --compressed --retry 3 --retry-delay 60 -o ./snyk-linux.sha256 https://static.snyk.io/cli/latest/snyk-linux.sha256 && \
    sha256sum -c snyk-linux.sha256 && \
    mv snyk-linux /usr/local/bin/snyk && \
    chmod +x /usr/local/bin/snyk

FROM alpine as snyk-alpine
RUN apk update && apk add --no-cache curl git
RUN curl --compressed --retry 3 --retry-delay 60 -o ./snyk-alpine https://static.snyk.io/cli/latest/snyk-alpine && \
    curl --compressed --retry 3 --retry-delay 60 -o ./snyk-alpine.sha256 https://static.snyk.io/cli/latest/snyk-alpine.sha256 && \
    sha256sum -c snyk-alpine.sha256 && \
    mv snyk-alpine /usr/local/bin/snyk && \
    chmod +x /usr/local/bin/snyk

FROM parent as alpine
RUN apk update && apk upgrade --no-cache
RUN apk add --no-cache libstdc++ git
COPY --from=snyk-alpine /usr/local/bin/snyk /usr/local/bin/snyk


FROM parent as linux
COPY --from=snyk /usr/local/bin/snyk /usr/local/bin/snyk
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y ca-certificates git
RUN apt-get auto-remove -y && apt-get clean -y && rm -rf /var/lib/apt/
