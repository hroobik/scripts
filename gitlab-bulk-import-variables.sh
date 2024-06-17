#!/bin/bash

# Replace with your GitLab details
GITLAB_API_URL="https://gitlab.example.com/api/v4"
PROJECT_ID="your_project_id"
PERSONAL_ACCESS_TOKEN="your_personal_access_token"
JSON_FILE="variables.json" #add variables file in json format

# Function to add variables to GitLab project
add_variable() {
  local key=$1
  local value=$2
  local protected=$3
  local masked=$4
  local environment_scope=$5

  curl --request POST "${GITLAB_API_URL}/projects/${PROJECT_ID}/variables" \
    --header "PRIVATE-TOKEN: ${PERSONAL_ACCESS_TOKEN}" \
    --header "Content-Type: application/json" \
    --data "{
      \"key\": \"${key}\",
      \"value\": \"${value}\",
      \"protected\": ${protected},
      \"masked\": ${masked},
      \"environment_scope\": \"${environment_scope}\"
    }"
}

# Read the JSON file and add each variable
jq -c '.[]' $JSON_FILE | while read -r var; do
  key=$(echo $var | jq -r '.key')
  value=$(echo $var | jq -r '.value')
  protected=$(echo $var | jq -r '.protected')
  masked=$(echo $var | jq -r '.masked')
  environment_scope=$(echo $var | jq -r '.environment_scope')

  add_variable "$key" "$value" "$protected" "$masked" "$environment_scope"
done
