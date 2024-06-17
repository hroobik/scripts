#!/bin/bash

# Constants for microservice names
USER_FACING_MICROS=("deployment_name_1" "deployment_name_2" "deployment_name_3")
SYSTEM_MICROS=("deployment_name_4" "deployment_name_5" "deployment_name_6" "deployment_name_7")
NAMESPACE="your_namespace"

# Function to scale a deployment
scale_deployment() {
  local deployment=$1
  local replicas=$2
  kubectl scale deployment $deployment -n $NAMESPACE --replicas=$replicas
}

# Function to check if a deployment is ready
check_deployment_ready() {
  local deployment=$1
  local expected_replicas=$2
  kubectl -n $NAMESPACE get deploy $deployment | grep -q "${expected_replicas}/${expected_replicas}"
  return $?
}

# Scale up primary microservice
echo "Scaling up primary microservice first"
scale_deployment "deployment_name_8" $1
echo "Waiting 20 seconds for deployment_name_8 to become available"
sleep 20

# Check if deployment_name_8 is ready
if ! check_deployment_ready "deployment_name_8" $1; then
  echo "deployment_name_8 is not ready, exiting"
  exit 1
else
  echo "deployment_name_8 is ready, scaling up system microservices"
fi

# Scale up system microservices
echo "Scaling up system microservices"
for micro in "${SYSTEM_MICROS[@]}"; do
  scale_deployment $micro 1
done

echo "Waiting 60 seconds for system microservices pods to be created"
sleep 60

# Check if system microservices are ready
for micro in "${SYSTEM_MICROS[@]}"; do
  if ! check_deployment_ready $micro 1; then
    echo "System microservice $micro is not ready, exiting"
    exit 1
  fi
done
echo "System microservices are ready, scaling the rest excluding front facing"

# Scale up other microservices
echo "Scaling up other microservices"
ALL_OTHER_MICROS=$(kubectl get deploy -n $NAMESPACE | grep deployment_name | grep -Ev 'deployment_name_1|deployment_name_2|deployment_name_3|deployment_name_4|deployment_name_5|deployment_name_6|deployment_name_7' | awk '{print $1}')
for micro in $ALL_OTHER_MICROS; do
  scale_deployment $micro $1
done

echo "Waiting 55 seconds for other microservices to be ready"
sleep 55

# Scale up user-facing microservices
echo "Scaling up user-facing microservices"
for micro in "${USER_FACING_MICROS[@]}"; do
  scale_deployment $micro $1
done
