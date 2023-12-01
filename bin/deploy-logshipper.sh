#!/bin/bash

if [ ! -d "cg-logshipper" ]; then
    git clone --depth 1 --branch usagov_updates git@github.com:GSA-TTS/cg-logshipper.git
else
    pushd cg-logshipper; git pull; popd;
fi

cp -rp project_conf cg-logshipper;

cd cg-logshipper;

cf push;
