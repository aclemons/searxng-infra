# syntax=docker/dockerfile:1.14.0@sha256:4c68376a702446fc3c79af22de146a148bc3367e73c25a5803d453b6b3f722fb

FROM public.ecr.aws/awsguru/aws-lambda-adapter:0.9.0@sha256:1c31bf4102ca63ef2082534d7139c0bc5fbd36ea6648e4756e9b475ef3ed829c AS aws-lambda-adapter

FROM searxng/searxng:2025.3.16-bbb2894b0@sha256:719399985d63294b08980ec23eb8bc2ab8d9ade3d101456abf18420fdd765f7d AS searxng


FROM public.ecr.aws/lambda/python:3.13.2025.04.03.11@sha256:6163db246a3595eaa5f2acf88525aefa3837fa54c6c105a3b10d18e7183b2d2b

# renovate: datasource=github-releases depName=awslabs/aws-lambda-web-adapter
ARG AWS_LAMBDA_WEB_ADAPTER_VERSION=v0.9.1

RUN curl --proto '=https' -sSf https://raw.githubusercontent.com/awslabs/aws-lambda-web-adapter/refs/tags/$AWS_LAMBDA_WEB_ADAPTER_VERSION/layer/bootstrap -o /opt/bootstrap && chmod 0755 /opt/bootstrap

COPY --link --from=aws-lambda-adapter /lambda-adapter /opt/extensions/lambda-adapter

# renovate: datasource=pypi depName=granian
ARG GRANIAN_VERSION=2.2.1

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
