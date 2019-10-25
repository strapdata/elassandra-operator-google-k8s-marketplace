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

get_cassandra_password() {
  # SECRET_NAME = "elassandra-${clusterName}"
  CASSANDRA_SECRET_NAME="elassandra-"$(get_cluster_name)
  kubectl get secrets $CASSANDRA_SECRET_NAME --namespace "${NAMESPACE}" -o yaml | grep "cassandra.cassandra_password" | cut -f2 -d':' | tr -d " " | base64 -d
}

for test in /tests/*; do
  testrunner "--test_spec=${test}"
done
