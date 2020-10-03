FROM ubuntu:20.04
COPY generate.sh /generate.sh
# COPY bin/opm /usr/local/bin
RUN apt-get update && apt-get install git curl tree -y
# Add temporary build fix.
# TODO: Use multistate build.
RUN curl -Lo /usr/local/bin/opm https://github.com/operator-framework/operator-registry/releases/download/v1.14.2/linux-amd64-opm && \
	chmod +x /usr/local/bin/opm

WORKDIR /github/workspace

# Setup a non-root user using the build args. This is required to avoid file
# permissions in the generated files inside the container.
# Refer: https://vsupalov.com/docker-shared-permissions/
# ARG USER_ID
# ARG GROUP_ID

# RUN addgroup --gid $GROUP_ID user
# RUN adduser --disabled-password --gecos '' --uid $USER_ID --gid $GROUP_ID user
# TODO: Find a way to pass docker build args in github actions build.
RUN addgroup --gid 1001 user
RUN adduser --disabled-password --gecos '' --uid 1001 --gid 1001 user
USER user

ENTRYPOINT ["/generate.sh"]
