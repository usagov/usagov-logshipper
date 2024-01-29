#!/bin/sh

# luacheck image tags include "latest" and "edge," "edge" being later than "latest"
docker run -it --rm \
      -v "$(pwd)/project_conf:/code/project_conf" \
      pipelinecomponents/luacheck:latest luacheck project_conf/scripts
