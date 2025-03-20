#!/bin/bash

set -e

cp "$LAMBDA_TASK_ROOT/searx/settings.yml" /tmp/settings.yml
cp "$LAMBDA_TASK_ROOT/searx/limiter.toml" /tmp/limiter.toml

sed -i -e "s/ultrasecretkey.*\"/$SEARXNG_SECRET_KEY\"/g" /tmp/settings.yml

export SEARXNG_SETTINGS_PATH="/tmp/settings.yml"

if [ -z "${AWS_LAMBDA_RUNTIME_API}" ]; then
  PATH=$PATH:$LAMBDA_TASK_ROOT/bin \
    PYTHONPATH=$PYTHONPATH:/opt/python:$LAMBDA_RUNTIME_DIR \
    exec -- /usr/local/bin/aws-lambda-rie python3 -m granian --interface wsgi searx.webapp
else
  PATH=$PATH:$LAMBDA_TASK_ROOT/bin \
    PYTHONPATH=$PYTHONPATH:/opt/python:$LAMBDA_RUNTIME_DIR \
    exec -- python3 -m granian --interface wsgi searx.webapp
fi
