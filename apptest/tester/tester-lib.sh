#!/bin/bash

info() {
  >&2 echo "${@}"
}

get_operator_name() {
  kubectl get deployments --namespace "${NAMESPACE}" -L operator=elassandra -o=jsonpath='{$.items[0].metadata.name}'
}

get_current_number_of_replicas_in_operator() {
  kubectl get deployments "${OPERATOR_NAME}" \
    --namespace "${NAMESPACE}" \
    --output jsonpath='{.status.readyReplicas}'
}

wait_for_operator_creation() {
  info "Waiting for operator creation"
  while [[ -z "$(get_operator_name)" ]]; do
    info "Sleeping 10 seconds before rechecking..."
    sleep 10
  done
  info "Operator deployement exists"
}

wait_for_healthy_operator() {
  info "Waiting for operator"
  while [[ $(get_current_number_of_replicas_in_operator) -ne 1 ]]; do
    info "Sleeping 10 seconds before rechecking..."
    sleep 10
  done
  info "Operator has equal current and desired number of replicas"
}

is_pod_ready() {
   [[ "$(kubectl get po "$1" --namespace ${NAMESPACE} -o 'jsonpath={.status.conditions[?(@.type=="Ready")].status}')" == 'True' ]]
}

get_sts_name() {
  kubectl get sts --namespace "${NAMESPACE}" -o name -l app=elassandra | cut -d '/' -f2 | cut -f1 -d ' '
}

wait_sts_creation() {
  info "Waiting for STS creation"
  while [[ -z "$(get_sts_name)" ]]; do
    info "Sleeping 10 seconds before rechecking..."
    sleep 10
  done
  info "Statefulset created"
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

get_numberOf_normal_nodes() {
  kubectl get elassandradatacenters.stable.strapdata.com --namespace "${NAMESPACE}" \
      -o=jsonpath='{$.items[0].status.elassandraNodeStatuses}' |  \
      sed 's/ /\n/g;s/\]//' | \
      cut -f2 -d':' | \
      grep -c "NORMAL"
}

wait_numberOf_pod_in_NORMAL_state() {
  info "Waiting for equal number of replicas in NORMAL state"
  while [[ "$(get_numberOf_normal_nodes)" -ne "$1" ]]; do
    info "Sleeping 10 seconds before rechecking..."
    sleep 10
  done
  info "$1 replicas in NORMAL state"
}
