FROM ubuntu:20.04
COPY generate.sh /generate.sh
COPY bin/opm /usr/local/bin
RUN apt-get update && apt-get install git -y

WORKDIR /github/workspace

# Setup a non-root user using the build args. This is required to avoid file
# permissions in the generated files inside the container.
# Refer: https://vsupalov.com/docker-shared-permissions/
ARG USER_ID
ARG GROUP_ID

RUN addgroup --gid $GROUP_ID user
RUN adduser --disabled-password --gecos '' --uid $USER_ID --gid $GROUP_ID user
USER user

ENTRYPOINT ["/generate.sh"]
