#!/bin/bash
#
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -xeo pipefail
shopt -s nullglob

source /tester-lib.sh


info "Wait for Operator"
wait_for_operator_creation

info "Wait all operator pods or running"
OPERATOR_NAME=$(get_operator_name)
wait_for_healthy_operator

kubectl get deployments "${OPERATOR_NAME}" \
--namespace "${NAMESPACE}" \
--output jsonpath='{.status.readyReplicas}'


info "Wait for StatefulSets"
wait_sts_creation
STS_NAME=$(get_sts_name)
wait_for_healthy_sts
kubectl get sts "${STS_NAME}" \
--namespace "${NAMESPACE}" \
--output jsonpath='{.status.readyReplicas}'

wait_pod_ready "${STS_NAME}-0"

wait_numberOf_pod_in_NORMAL_state 1

CLUSTER_NAME=$(get_cluster_name)
DATACENTER_NAME=$(get_datacenter_name)

CASSANDRA_PASSWORD=$(get_cassandra_password)
export ELASSANDRA_HOST="${STS_NAME}-0.elassandra-${CLUSTER_NAME}-${DATACENTER_NAME}.${NAMESPACE}.svc.cluster.local"
#cqlsh -u cassandra -p ${CASSANDRA_PASSWORD} -e 'SHOW HOST' --cqlversion="3.4.4" "${ELASSANDRA_HOST}" 39042 2>&1

info "Check ES connection"
curl -u "cassandra:${CASSANDRA_PASSWORD}" --insecure "https://${ELASSANDRA_HOST}:9200/" 2>&1

# TODO clean by scaling down to 0...
# "Clean to close the tester (otherwise it will wait for the termination of resources...)"

STS_NAME=$(get_sts_name)
CLUSTER_NAME=$(get_cluster_name)
DATACENTER_NAME=$(get_datacenter_name)

kubectl delete -n  "${NAMESPACE}" elassandradatacenter elassandra-${CLUSTER_NAME}-${DATACENTER_NAME}
kubectl delete sts "${STS_NAME}" --namespace "${NAMESPACE}"
kubectl delete -n  "${NAMESPACE}" svc -l app=elassandra
#kubectl delete -n  "${NAMESPACE}" pvc -l app=elassandra
