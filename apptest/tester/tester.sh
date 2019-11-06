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

is_pod_ready() {
   [[ "$(kubectl get po "$1" --namespace ${NAMESPACE} -o 'jsonpath={.status.conditions[?(@.type=="Ready")].status}')" == 'True' ]]
}

get_sts_name() {
  kubectl get sts --namespace "${NAMESPACE}" | grep ^elassandra | cut -f1 -d ' '
}

get_cluster_name() {
  kubectl get elassandradatacenters.stable.strapdata.com --namespace "${NAMESPACE}" -o=jsonpath='{$.items[0].spec.clusterName}'
}

get_datacenter_name() {
  kubectl get elassandradatacenters.stable.strapdata.com --namespace "${NAMESPACE}" -o=jsonpath='{$.items[0].spec.datacenterName}'
}

get_cassandra_password() {
  # SECRET_NAME = "elassandra-${clusterName}"
  CASSANDRA_SECRET_NAME="elassandra-"$(get_cluster_name)
  kubectl get secrets $CASSANDRA_SECRET_NAME --namespace "${NAMESPACE}" -o yaml | grep "cassandra.cassandra_password" | cut -f2 -d':' | tr -d " " | base64 -d
}

get_desired_number_of_replicas_in_sts() {
  kubectl get sts "${STS_NAME}" \
    --namespace "${NAMESPACE}" \
    --output jsonpath='{.spec.replicas}'
}

get_current_number_of_replicas_in_sts() {
  kubectl get sts "${STS_NAME}" \
    --namespace "${NAMESPACE}" \
    --output jsonpath='{.status.readyReplicas}'
}

wait_for_healthy_sts() {
  info "Waiting for equal desired and current number of replicas"
  while [[ $(get_current_number_of_replicas_in_sts) -ne $(get_desired_number_of_replicas_in_sts) ]]; do
    info "Sleeping 10 seconds before rechecking..."
    sleep 10
  done
  info "Statefulset has equal current and desired number of replicas"
}

is_pod_ready() {
   [[ "$(kubectl get po "$1" --namespace ${NAMESPACE} -o 'jsonpath={.status.conditions[?(@.type=="Ready")].status}')" == 'True' ]]
}

wait_pod_ready(){
  while true; do
    echo "waiting for pod $1 to be ready"
    is_pod_ready $1 && return 0
    sleep 1
  done
}


for test in /tests/*; do
  testrunner "--test_spec=${test}"
done
