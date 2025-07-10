#!/usr/bin/env bash

#####################################################################
##
## This is meant to be a temporary script for disaster recovery
## (used in conjunction with usagov-2021's script of the same name).
##
#####################################################################

# just testing?
if [ x$1 = x"--dryrun" ]; then
  echo=echo
  dryrun=$1
  shift
fi

ORG=gsa-tts-usagov
APP_SPACE=dr
LOG_SHIPPER_SPACE=dr
EGRESS_SPACE=shared-egress
echo "ORG:                $ORG"
echo "LOG_SHIPPER_SPACE:  $LOG_SHIPPER_SPACE"
echo "EGRESS_SPACE:       $EGRESS_SPACE"

HTTP_USER=${HTTP_USER:-`uuidgen`}
HTTP_PASS=${HTTP_PASS:-`uuidgen`}
# Save these; you will need to set them for a later step (if not in the same session)
echo "HTTP_USER:    $HTTP_USER"
echo "HTTP_PASS:    $HTTP_PASS"

if [ -z "$NEW_RELIC_LICENSE_KEY" ]; then
  echo "NEW_RELIC_LICENSE_KEY is not set. Please set it before proceeding."
  echo "To get a key, go to one.newrelic.com and generate a new “INGEST - LICENSE” key"
  exit 1
else
  echo "NEW_RELIC_LICENSE_KEY:  $NEW_RELIC_LICENSE_KEY"
fi

# Setup services
 echo cf target -o $ORG -s $LOG_SHIPPER_SPACE
 $echo cf target -o $ORG -s $LOG_SHIPPER_SPACE
 echo ./bin/setup-services.sh
 $echo ./bin/setup-services.sh
 exit

# Deploy log-shipper
 echo ./bin/deploy-logshipper.sh 0000
 $echo ./bin/deploy-logshipper.sh 0000
 exit

# Create routes
 echo cf create-route app.cloud.gov --hostname usagov-${LOG_SHIPPER_SPACE}-logshipper
 $echo cf create-route app.cloud.gov --hostname usagov-${LOG_SHIPPER_SPACE}-logshipper
 echo cf map-route log-shipper app.cloud.gov --hostname usagov-${LOG_SHIPPER_SPACE}-logshipper
 $echo cf map-route log-shipper app.cloud.gov --hostname usagov-${LOG_SHIPPER_SPACE}-logshipper
 exit

# Bind services
 echo cf bind-service log-shipper newrelic-creds
 $echo cf bind-service log-shipper newrelic-creds
 echo cf bind-service log-shipper cg-logshipper-creds
 $echo cf bind-service log-shipper cg-logshipper-creds
 echo cf bind-service log-shipper log-storage
 $echo cf bind-service log-shipper log-storage
 exit

# Add network policies
 echo cf add-network-policy log-shipper ${LOG_SHIPPER_SPACE}-proxy --protocol tcp --port 61443 -s ${EGRESS_SPACE}
 $echo cf add-network-policy log-shipper ${LOG_SHIPPER_SPACE}-proxy --protocol tcp --port 61443 -s ${EGRESS_SPACE}
 exit

#
# Set up log drains for app space
#
HOSTNAME="usagov-${LOG_SHIPPER_SPACE}"
echo "APP_SPACE:          $APP_SPACE"
echo "LOG_SHIPPER_SPACE:  $LOG_SHIPPER_SPACE"
echo "HOSTNAME:           $HOSTNAME"
echo "EGRESS_SPACE:       $EGRESS_SPACE"
echo "Do not proceed if these are not set: "
echo "HTTP_USER:    $HTTP_USER"
echo "HTTP_PASS:    $HTTP_PASS"

spacelist=("${APP_SPACE}" "${EGRESS_SPACE}")
for space in ${spacelist[@]}; do
    echo cf target -s $space
    $echo cf target -s $space
    echo ./bin/add-log-drains-for-space.sh
    $echo ./bin/add-log-drains-for-space.sh
done
