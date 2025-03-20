# syntax=docker/dockerfile:1.14.0

FROM public.ecr.aws/awsguru/aws-lambda-adapter:0.9.0 AS aws-lambda-adapter

FROM searxng/searxng:2025.3.16-bbb2894b0 AS searxng


FROM public.ecr.aws/lambda/python:3.13.2025.03.14.16

# renovate: datasource=github-releases depName=awslabs/aws-lambda-web-adapter
ARG AWS_LAMBDA_WEB_ADAPTER_VERSION=v0.9.0

RUN curl --proto '=https' -sSf https://raw.githubusercontent.com/awslabs/aws-lambda-web-adapter/refs/tags/$AWS_LAMBDA_WEB_ADAPTER_VERSION/layer/bootstrap -o /opt/bootstrap && chmod 0755 /opt/bootstrap

COPY --link --from=aws-lambda-adapter /lambda-adapter /opt/extensions/lambda-adapter

# renovate: datasource=pypi depName=granian
ARG GRANIAN_VERSION=2.1.1

# hadolint ignore=DL3042,DL3013
RUN --mount=type=cache,target=/root/.cache/pip \
    pip3 install --root-user-action ignore --disable-pip-version-check --no-color --no-python-version-warning --timeout 100 --no-input --target "$LAMBDA_TASK_ROOT" granian==$GRANIAN_VERSION

# hadolint ignore=DL3042
RUN --mount=from=searxng,source=/usr/local/searxng/requirements.txt,target=/tmp/requirements.txt \
    --mount=type=cache,target=/root/.cache/pip \
    pip3 install --root-user-action ignore --disable-pip-version-check --no-color --no-python-version-warning --timeout 100 --no-input --target "$LAMBDA_TASK_ROOT" -r /tmp/requirements.txt

WORKDIR "$LAMBDA_TASK_ROOT"

COPY --chown=root:root --link --from=searxng /usr/local/searxng/searx searx

COPY run.sh .
