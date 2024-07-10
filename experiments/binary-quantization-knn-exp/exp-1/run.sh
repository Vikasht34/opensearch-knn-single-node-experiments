#!/bin/bash

set -xe

# Simple wrapper script that will give opportunity to run tests with
# different memory limits for one run versus another.
#
# Usage:
# **Note - this needs to be run from the root of the project for now...**
#
# bash experiments/exp-low-mem-knn/run.sh <method> <rescore context> <compression level>
#
#
# Params:
#   method: hnsw, ivf, hnswpq, ivfpq
#   rescore context: 0r, 2r, 10r
#   compression level: 1x, 8x, 16x, 32x
METHOD=$1
RESCORE_CONTEXT=$2
COMPRESSION_LEVEL=$3

# Constants
EXPERIMENT_PATH="experiments/low-mem-knn-exp/exp-1"
BASE_ENV_PATH="${EXPERIMENT_PATH}/env/${COMPRESSION_LEVEL}"
INDEX_ENV_PATH="${BASE_ENV_PATH}/index-build.env"
SEARCH_ENV_PATH="${BASE_ENV_PATH}/search.env"
OSB_PARAMS_PATH="osb/custom/params"
PARAMS_PATH="${EXPERIMENT_PATH}/osb-params/${COMPRESSION_LEVEL}"
TMP_ENV_DIR="${EXPERIMENT_PATH}/tmp"
TMP_ENV_NAME="test.env"
TMP_ENV_PATH="${EXPERIMENT_PATH}/${TMP_ENV_NAME}"

source ${EXPERIMENT_PATH}/functions.sh

OSB_INDEX_PROCEDURE="no-train-test-index-with-merge"



# Copy params to OSB folder
cp ${PARAMS_PATH}/${METHOD}-1c${RESCORE_SUFFIX}.json ${OSB_PARAMS_PATH}/
cp ${PARAMS_PATH}/${METHOD}-4c${RESCORE_SUFFIX}.json ${OSB_PARAMS_PATH}/
cp ${PARAMS_PATH}/${METHOD}-16c${RESCORE_SUFFIX}.json ${OSB_PARAMS_PATH}/

# Initialize shared data folder for containers
mkdir -m 777 /tmp/share-data

setup_environment ${TMP_ENV_DIR} ${TMP_ENV_NAME} "index-build" ${METHOD}-1c${RESCORE_SUFFIX}.json ${OSB_INDEX_PROCEDURE} false
docker compose --env-file ${INDEX_ENV_PATH} --env-file ${TMP_ENV_PATH} -f compose.yaml up -d

wait_for_container_stop osb
setup_environment ${TMP_ENV_DIR} ${TMP_ENV_NAME} "search-1c" ${METHOD}-1c${RESCORE_SUFFIX}.json "search-only" true
docker compose --env-file ${SEARCH_ENV_PATH} --env-file ${TMP_ENV_PATH} -f compose.yaml up -d
clear_cache

wait_for_container_stop osb
setup_environment ${TMP_ENV_DIR} ${TMP_ENV_NAME} "search-4c" ${METHOD}-4c${RESCORE_SUFFIX}.json "search-only" true
docker compose --env-file ${SEARCH_ENV_PATH} --env-file ${TMP_ENV_PATH} -f compose.yaml up -d
clear_cache

wait_for_container_stop osb
setup_environment ${TMP_ENV_DIR} ${TMP_ENV_NAME} "search-16c" ${METHOD}-16c${RESCORE_SUFFIX}.json "search-only" true
docker compose --env-file ${SEARCH_ENV_PATH} --env-file ${TMP_ENV_PATH} -f compose.yaml up -d
clear_cache

# Add at the end to ensure container finishes
wait_for_container_stop osb

echo "Finished all runs"
