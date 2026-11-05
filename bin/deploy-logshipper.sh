#!/bin/bash

NUM_INSTANCES=${1:-"1"}
CONTAINERTAG=${2:-"/no pipeline number/"}

# cg-logshipper commit to deploy. A commit (not a branch or tag) so upstream
# changes never arrive unannounced; upstream branches/tags have been removed
# before. 4bb76d0 is the commit behind upstream's "fluent-5.0" tag and main.
CG_LOGSHIPPER_COMMIT="4bb76d0174e8a5c413cc24e96c7d3dc5c9fbd4d8"

# Fluent Bit version for apt, overriding the exact pin in cg-logshipper's apt.yml.
# "5.1.*" picks up 5.1 patch releases on each deploy, never a new minor/major.
# Keep this quoted wherever it is used so the shell never glob-expands the "*".
FLUENT_BIT_VERSION="5.1.*"

function appExists {  # appname
  app=$1
  if [ -z "$app" ]; then
    echo "ERROR: appname is required"
    exit 1
  fi
  cf app $app > /dev/null 2>&1
  return $?
}



# Get our branch and commit has for the status file:
USAGOV_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")
USAGOV_COMMIT=$(git log -1 --pretty=format:"%H")

# Always clear out the old cg-logshipper directory. We need to do this
# if we've changed the branch/tag we want to deploy or if we've removed some files
# from project_conf; it's easiest to just do it every time.
if [ -d "cg-logshipper" ]; then
   rm -rf cg-logshipper
fi

# Clone cg-logshipper and check out a specific commit.
git clone git@github.com:GSA-TTS/cg-logshipper.git || exit 1
git -C cg-logshipper -c advice.detachedHead=false checkout "${CG_LOGSHIPPER_COMMIT}" || exit 1

# Copy in our own custom config
cp -rp project_conf cg-logshipper

cd cg-logshipper || exit 1

# Override the Fluent Bit version pinned in cg-logshipper's apt.yml.
# -i.bak works with both BSD and GNU sed; the .bak is removed so it isn't pushed.
sed -i.bak -E "s/^([[:space:]]*-[[:space:]]*fluent-bit=).*/\1${FLUENT_BIT_VERSION}/" apt.yml
rm -f apt.yml.bak
if ! grep -qxF -- "- fluent-bit=${FLUENT_BIT_VERSION}" apt.yml; then
    echo "ERROR: could not set fluent-bit=${FLUENT_BIT_VERSION} in cg-logshipper/apt.yml; aborting deploy."
    exit 1
fi
echo "Fluent Bit version for apt: ${FLUENT_BIT_VERSION}"

# Write a status file we can inspect if needed:
echo "USAGov log-shipper deployment version:" >> ./DEPLOYED_VERSION.txt
echo "    built:" $(date) >> ./DEPLOYED_VERSION.txt
echo "    usagov-logshipper branch:" $USAGOV_BRANCH >> ./DEPLOYED_VERSION.txt
echo "    usagov-logshipper commit:" $USAGOV_COMMIT >> ./DEPLOYED_VERSION.txt
echo "    cg-logshipper commit:" $(git log -1 --pretty=format:"%H") >> ./DEPLOYED_VERSION.txt
echo "    fluent-bit version pin: ${FLUENT_BIT_VERSION}" >> ./DEPLOYED_VERSION.txt
echo "    containertag:" $CONTAINERTAG >> ./DEPLOYED_VERSION.txt

NO_ROUTE="--no-route"
if appExists log-shipper; then
    NO_ROUTE=""
fi

# Push the app from the cg-logshipper directory
cf push log-shipper --instances ${NUM_INSTANCES} ${NO_ROUTE} --memory 256M --strategy rolling
