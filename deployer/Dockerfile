#FROM launcher.gcr.io/google/debian9 AS build
#
#RUN apt-get update \
#    && apt-get install -y --no-install-recommends gettext
#
#ADD chart/elassandra-operator /tmp/chart
#RUN cd /tmp && tar -czvf /tmp/elassandra-operator.tar.gz chart
#
#ADD apptest/deployer/elassandra-operator /tmp/test/chart
#RUN cd /tmp/test \
#&& tar -czvf /tmp/test/elassandra-operator.tar.gz chart/
#
#ADD schema.yaml /tmp/schema.yaml
#
#
#ARG REGISTRY
#ARG TAG
#
#RUN cat /tmp/schema.yaml \
#    | env -i "REGISTRY=$REGISTRY" "TAG=$TAG" envsubst \
#    > /tmp/schema.yaml.new \
#    && mv /tmp/schema.yaml.new /tmp/schema.yaml
#
#FROM gcr.io/cloud-marketplace-tools/k8s/deployer_helm
#COPY --from=build /tmp/elassandra-operator.tar.gz /data/chart/
#COPY --from=build /tmp/test/elassandra-operator.tar.gz /data-test/chart/
#COPY apptest/deployer/schema.yaml /data-test/
#COPY --from=build /tmp/schema.yaml /data/
#
## increase test timeout because 3-nodes elassandra cluter takes time to be fully ready
#ENV TESTER_TIMEOUT 500
ARG MARKETPLACE_TOOLS_TAG
FROM gcr.io/cloud-marketplace-tools/k8s/deployer_envsubst:$MARKETPLACE_TOOLS_TAG

COPY manifest/* /data/manifest/
COPY schema.yaml /data/
COPY apptest/deployer /data-test/


# Provide registry prefix and tag for default values for images.
ARG REGISTRY
ARG TAG
RUN cat /data/schema.yaml \
    | env -i "REGISTRY=$REGISTRY" "TAG=$TAG" envsubst \
    > /data/schema.yaml.new \
    && mv /data/schema.yaml.new /data/schema.yaml

RUN cat /data-test/schema.yaml \
    | env -i "REGISTRY=$REGISTRY" "TAG=$TAG" envsubst \
    > /data-test/schema.yaml.new \
    && mv /data-test/schema.yaml.new /data-test/schema.yaml