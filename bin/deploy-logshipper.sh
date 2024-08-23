#!/bin/bash

CONTAINERTAG=${1:-"/no pipeline number/"}

# Get our branch and commit has for the status file:
USAGOV_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")
USAGOV_COMMIT=$(git log -1 --pretty=format:"%H")

# Always clear out the old cg-logshipper directory. We need to do this
# if we've changed the branch/tag we want to deploy or if we've removed some files
# from project_conf; it's easiest to just do it every time.
if [ -d "cg-logshipper" ]; then
   rm -rf cg-logshipper
fi

# Clone cg-logshipper and check out a specific commit
git clone git@github.com:GSA-TTS/cg-logshipper.git
pushd cg-logshipper
git checkout 9b00429
popd


# Copy in our own custom config
cp -rp project_conf cg-logshipper

cd cg-logshipper

# Write a status file we can inspect if needed:
echo "USAGov log-shipper deployment version:" >> ./DEPLOYED_VERSION.txt
echo "    built:" $(date) >> ./DEPLOYED_VERSION.txt
echo "    usagov-logshipper branch:" $USAGOV_BRANCH >> ./DEPLOYED_VERSION.txt
echo "    usagov-logshipper commit:" $USAGOV_COMMIT >> ./DEPLOYED_VERSION.txt
echo "    cg-logshipper commit:" $(git log -1 --pretty=format:"%H") >> ./DEPLOYED_VERSION.txt
echo "    containertag:" $CONTAINERTAG >> ./DEPLOYED_VERSION.txt

# And push the app from the cg-logshipper directory
cf push log-shipper --instances 2 --random-route --strategy rolling
