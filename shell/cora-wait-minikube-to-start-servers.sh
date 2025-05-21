#!/bin/bash
if [ -z "$1" ]; then
  echo "Usage: $0 <MINIKUBE_IP>"
  exit 1
fi

MINIKUBE_IP="$1"
APPLICATION="$2"

URLS=(
  "http://$MINIKUBE_IP:31080/$APPLICATION/rest/"
  "http://$MINIKUBE_IP:31180/login/"
  "http://$MINIKUBE_IP:31580/fitnesse/"
  #"http://$MINIKUBE_IP:30380/idplogin/login/"
)

MAX_ATTEMPTS=30
SLEEP_SECONDS=10

echo "Waiting for all URLs to become accessible..."

for URL in "${URLS[@]}"; do
  attempt=1
  while (( attempt <= MAX_ATTEMPTS )); do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
    if [ "$HTTP_CODE" == "200" ]; then
      echo "Success: $URL is accessible."
      break
    else
      echo "Attempt $attempt/$MAX_ATTEMPTS failed for $URL (HTTP $HTTP_CODE). Retrying in $SLEEP_SECONDS seconds..."
      (( attempt++ ))
      sleep $SLEEP_SECONDS
    fi
  done

  if (( attempt > MAX_ATTEMPTS )); then
    echo "Error: $URL did not become accessible after $MAX_ATTEMPTS attempts."
    exit 1
  fi
done

echo "All URLs are accessible. Continuing with the batch job..."