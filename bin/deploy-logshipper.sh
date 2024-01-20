#!/bin/bash

# Always clear out the old cg-logshipper directory. We need to do this
# if we've changed the branch/tag we want to deploy or if we've removed some files
# from project_conf; it's easiest to just do it every time.
if [ -d "cg-logshipper" ]; then
   rm -rf cg-logshipper
fi

# Clone cg-logshipper at the specified branch/tag
git clone --depth 1 --branch usagov-1.0 git@github.com:usagov/cg-logshipper.git

cp -rp project_conf cg-logshipper

cd cg-logshipper

cf push log-shipper --instances 2 --strategy rolling
