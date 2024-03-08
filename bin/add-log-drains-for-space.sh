#!/bin/bash

# Adds a log drain for the specified space and binds it to each app
# EXCEPT for "log-shipper"

set -e

SERVICE_EXISTS=`cf service log-shipper-drain --guid`

if [ "$SERVICE_EXISTS" = "FAILED" ]; then
    echo "Creating log-shipper-drain service"
    cf create-user-provided-service log-shipper-drain -l "https://${HTTP_USER}:${HTTP_PASS}@usagov-tools-logshipper.app.cloud.gov/?drain-type=all"
else
    echo "Service log-shipper-drain already exists."
fi


applist=$(cf apps | tail -n +4 | awk '{print $1}')

for app in $applist; do
    if [[ ! "$app" = "log-shipper" ]]; then
	echo "Binding log-shipper-drain service to $app"
        cf bind-service $app log-shipper-drain
    fi
done
