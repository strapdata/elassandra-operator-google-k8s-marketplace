FROM gcr.io/cloud-marketplace-tools/testrunner:0.1.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    gettext \
    jq \
    uuid-runtime \
    wget \
    python \
    python-pip \
    python-setuptools \
    curl \
    && pip install --upgrade pip \
    && python -m pip install --upgrade wheel \
    && python -m pip install cqlsh \
    && rm -rf /var/lib/apt/lists/*

RUN wget -q -O /bin/kubectl \
    https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kubectl \
      && chmod 755 /bin/kubectl

COPY tests/basic-suite.yaml /tests/basic-suite.yaml
COPY tester.sh /tester.sh
COPY tester-lib.sh /tester-lib.sh

WORKDIR /
ENTRYPOINT ["/tester.sh"]
