#!/bin/bash

set -xe

# Usage:
# bash experiments/BinaryQuantization/run.sh <compression level> <ef search value> <query K>
#
# Params:
#   compression level: e.g., 1x, 8x, 32x, 32x
#   ef search value: integer value for ef search

COMPRESSION_LEVEL=$1
SEARCH_CLIENT=$2
EF_SEARCH=$3

# Constants
EXPERIMENT_PATH="experiments/binary-quantization-end-to-end-exp/exp-7"
BASE_ENV_PATH="${EXPERIMENT_PATH}/env/${COMPRESSION_LEVEL}"
INDEX_ENV_PATH="${BASE_ENV_PATH}/index-build.env"
SEARCH_ENV_PATH="${BASE_ENV_PATH}/search.env"
OSB_PARAMS_PATH="osb/custom/params"
PARAMS_PATH="${EXPERIMENT_PATH}/osb-params/${COMPRESSION_LEVEL}/sc-${SEARCH_CLIENT}/ef-search-${EF_SEARCH}"
TMP_ENV_DIR="${EXPERIMENT_PATH}/tmp"
TMP_ENV_NAME="test.env"
TMP_ENV_PATH="${EXPERIMENT_PATH}/${TMP_ENV_NAME}"
STOP_PROCESS_PATH="/tmp/share-data/stop.txt"

source ${EXPERIMENT_PATH}/functions.sh


# Derive procedure for indexing and search information
OSB_INDEX_PROCEDURE="no-train-test-index-with-merge"

# Copy params to OSB folder
cp ${PARAMS_PATH}/100.json ${OSB_PARAMS_PATH}/

# Initialize shared data folder for containers
mkdir -m 777 /tmp/share-data

aws s3 cp s3://knn-all-datasets/open-ai-1536-temp.hdf5 /tmp/share-data/open-ai-1536-temp.hdf5

setup_environment ${TMP_ENV_DIR} ${TMP_ENV_NAME} "index-build" 100.json ${OSB_INDEX_PROCEDURE} false
docker compose --env-file ${INDEX_ENV_PATH} --env-file ${TMP_ENV_PATH} -f compose.yaml up -d

#wait_for_container_stop osb
#echo stop > ${STOP_PROCESS_PATH}
#sleep 10
#setup_environment ${TMP_ENV_DIR} ${TMP_ENV_NAME} "search-100" 100.json "search-only" true
#docker compose --env-file ${SEARCH_ENV_PATH} --env-file ${TMP_ENV_PATH} -f compose.yaml up -d
#clear_cache

#wait_for_container_stop osb
#setup_environment ${TMP_ENV_DIR} ${TMP_ENV_NAME} "search-200" 200.json "search-only" true
#docker compose --env-file ${SEARCH_ENV_PATH} --env-file ${TMP_ENV_PATH} -f compose.yaml up -d
#clear_cache
#
#wait_for_container_stop osb
#setup_environment ${TMP_ENV_DIR} ${TMP_ENV_NAME} "search-300" 300.json "search-only" true
#docker compose --env-file ${SEARCH_ENV_PATH} --env-file ${TMP_ENV_PATH} -f compose.yaml up -d
#clear_cache
#
#wait_for_container_stop osb
#setup_environment ${TMP_ENV_DIR} ${TMP_ENV_NAME} "search-400" 400.json "search-only" true
#docker compose --env-file ${SEARCH_ENV_PATH} --env-file ${TMP_ENV_PATH} -f compose.yaml up -d
#clear_cache
#
#wait_for_container_stop osb
#setup_environment ${TMP_ENV_DIR} ${TMP_ENV_NAME} "search-500" 500.json "search-only" true
#docker compose --env-file ${SEARCH_ENV_PATH} --env-file ${TMP_ENV_PATH} -f compose.yaml up -d
#clear_cache

# Add at the end to ensure container finishes
#wait_for_container_stop osb
#echo stop > ${STOP_PROCESS_PATH}
#sleep 10
#echo "Finished all runs"
