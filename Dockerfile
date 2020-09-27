FROM ubuntu:20.04
COPY generate.sh /generate.sh
COPY bin/opm /usr/local/bin
RUN apt-get update && apt-get install git -y

ENTRYPOINT ["/generate.sh"]
