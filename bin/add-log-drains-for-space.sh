#!/bin/bash
# Adds a log drain for the specified space and binds it to each app
# EXCEPT for "log-shipper"

set -o pipefail

DRAIN_NAME=${1:-"log-shipper-drain"}

if [ -z "$HOSTNAME" ]; then
    echo "HOSTNAME var is not set"
    exit 1
fi

SERVICE_EXISTS=$(cf service ${DRAIN_NAME} --guid)

if [ "$SERVICE_EXISTS" = "FAILED" ]; then
    echo "Creating ${DRAIN_NAME} service"
    cf create-user-provided-service ${DRAIN_NAME} -l "https://${HTTP_USER}:${HTTP_PASS}@${HOSTNAME}-logshipper.app.cloud.gov/?drain-type=all"
else
    echo "Service ${DRAIN_NAME} already exists."
fi


applist=$(cf apps | tail -n +4 | awk '{print $1}')

for app in $applist; do
    if [[ ! "$app" = "log-shipper" ]]; then
	echo "Binding ${DRAIN_NAME} service to $app"
        cf bind-service $app ${DRAIN_NAME}
    fi
done
