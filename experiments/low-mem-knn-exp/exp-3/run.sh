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
#   rescore context: 0r, 1r, 2r
#   compression level: 8x, 12x, 32x, 24x
METHOD=$1
RESCORE_CONTEXT=$2
COMPRESSION_LEVEL=$3

# Constants
EXPERIMENT_PATH="experiments/low-mem-knn-exp/exp-3"
BASE_ENV_PATH="${EXPERIMENT_PATH}/env/${COMPRESSION_LEVEL}"
INDEX_ENV_PATH="${BASE_ENV_PATH}/index-build.env"
SEARCH_ENV_PATH="${BASE_ENV_PATH}/search.env"
OSB_PARAMS_PATH="osb/custom/params"
TMP_ENV_DIR="${EXPERIMENT_PATH}/tmp"
TMP_ENV_NAME="test.env"
TMP_ENV_PATH="${EXPERIMENT_PATH}/${TMP_ENV_NAME}"
STOP_PROCESS_PATH="/tmp/share-data/stop.txt"

source ${EXPERIMENT_PATH}/functions.sh

# Derive procedure for indexing and rescoring information
RESCORE_SUFFIX="-${RESCORE_CONTEXT}"
OSB_INDEX_PROCEDURE="train-test-index-with-merge"

# Were only providing 2 different compression levels from param perspective
if [[ "$METHOD" == "hnswpq" ]]; then
  PARAMS_PATH="${EXPERIMENT_PATH}/osb-params/32x"
else
  if [[ "$COMPRESSION_LEVEL" == "8x" ]] || [[ "$COMPRESSION_LEVEL" == "12x" ]]; then
    PARAMS_PATH="${EXPERIMENT_PATH}/osb-params/16x"
  else
    PARAMS_PATH="${EXPERIMENT_PATH}/osb-params/32x"
  fi
fi

# Copy params to OSB folder
cp ${PARAMS_PATH}/${METHOD}-1c${RESCORE_SUFFIX}.json ${OSB_PARAMS_PATH}/
cp ${PARAMS_PATH}/${METHOD}-2c${RESCORE_SUFFIX}.json ${OSB_PARAMS_PATH}/
cp ${PARAMS_PATH}/${METHOD}-4c${RESCORE_SUFFIX}.json ${OSB_PARAMS_PATH}/

# Initialize shared data folder for containers
mkdir -p -m 777 /tmp/share-data
mkdir -p -m 777 /tmp/share-data/telemetry

# Run io-poll.sh in background
bash ${EXPERIMENT_PATH}/io-poll.sh /tmp/share-data/telemetry/iostats.csv &

setup_environment ${TMP_ENV_DIR} ${TMP_ENV_NAME} "index-build" ${METHOD}-1c${RESCORE_SUFFIX}.json ${OSB_INDEX_PROCEDURE} false
docker compose --env-file ${INDEX_ENV_PATH} --env-file ${TMP_ENV_PATH} -f compose.yaml up -d

wait_for_container_stop osb
echo stop > ${STOP_PROCESS_PATH}
sleep 10
setup_environment ${TMP_ENV_DIR} ${TMP_ENV_NAME} "search-1c" ${METHOD}-1c${RESCORE_SUFFIX}.json "search-only" true
docker compose --env-file ${SEARCH_ENV_PATH} --env-file ${TMP_ENV_PATH} -f compose.yaml up -d
clear_cache

wait_for_container_stop osb
echo stop > ${STOP_PROCESS_PATH}
sleep 10
setup_environment ${TMP_ENV_DIR} ${TMP_ENV_NAME} "search-2c" ${METHOD}-2c${RESCORE_SUFFIX}.json "search-only" true
docker compose --env-file ${SEARCH_ENV_PATH} --env-file ${TMP_ENV_PATH} -f compose.yaml up -d
clear_cache

wait_for_container_stop osb
echo stop > ${STOP_PROCESS_PATH}
sleep 10
setup_environment ${TMP_ENV_DIR} ${TMP_ENV_NAME} "search-4c" ${METHOD}-4c${RESCORE_SUFFIX}.json "search-only" true
docker compose --env-file ${SEARCH_ENV_PATH} --env-file ${TMP_ENV_PATH} -f compose.yaml up -d
clear_cache

# Add at the end to ensure container finishes
wait_for_container_stop osb
echo stop > ${STOP_PROCESS_PATH}
sleep 10

echo "Finished all runs"
