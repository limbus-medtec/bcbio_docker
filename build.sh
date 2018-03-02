#!/bin/bash
set -ex -o pipefail

BCBIO_VERSION="1.0.9a"
BCBIO_REVISION="59c72b7"
NS="quay.io/bcbio"
TAG="${BCBIO_VERSION}-${BCBIO_REVISION}"

# build bcbio base
docker pull ubuntu:16.04
docker build --no-cache --build-arg "git_revision=${BCBIO_REVISION}" -t "${NS}/bcbio-base:${TAG}" -t "${NS}/bcbio-base:latest" - < Dockerfile.base

# build bcbio + task specific tools
for TOOL in ${TOOLS}
do
    df -h
    docker build --no-cache --build-arg "git_revision=${BCBIO_REVISION}" --build-arg "tool=${TOOL}" -t "${NS}/${TOOL}:${TAG}" -t "${NS}/${TOOL}:latest" -f Dockerfile.tools .
    df -h
done

# log in to quay.io
set +x # avoid leaking encrypted password into travis log
docker login -u="bcbio+travis" -p="$QUAY_PASSWORD" quay.io

# push images
set -ex -o pipefail
docker push "${NS}/bcbio-base:${TAG}"
docker push "${NS}/bcbio-base:latest"
for TOOL in ${TOOLS}
do
    docker push "${NS}/${TOOL}:${TAG}"
    docker push "${NS}/${TOOL}:latest"
done
