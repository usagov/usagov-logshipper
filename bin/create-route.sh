#!/bin/bash

HOSTNAME=${1}

# Create a route for the log-shipper, using ${HOSTNAME}-logshipper as the host name.
if [ -z "$HOSTNAME" ]; then
    echo "No string supplied for the hostname"
    exit 1
fi

cf create-route app.cloud.gov --hostname ${HOSTNAME}-logshipper
cf map-route log-shipper app.cloud.gov --hostname ${HOSTNAME}-logshipper
