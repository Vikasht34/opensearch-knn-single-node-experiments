#!/bin/bash

setup_environment() {
    local TMP_ENV_DIR="$1"
    local TMP_ENV_NAME="$2"
    local RUN_ID="$3"
    local OSB_PARAMS="$4"
    local OSB_PROCEDURE="$5"
    local OSB_SHOULD_PROFILE="$6"

    mkdir -p ${TMP_ENV_DIR}
    TMP_ENV_PATH="${TMP_ENV_DIR}/${TMP_ENV_NAME}"
    rm -rf ${TMP_ENV_PATH}
    echo "RUN_ID=${RUN_ID}" >> "${TMP_ENV_PATH}"
    echo "OSB_PARAMS=${OSB_PARAMS}" >> "${TMP_ENV_PATH}"
    echo "OSB_PROCEDURE=${OSB_PROCEDURE}" >> "${TMP_ENV_PATH}"
    echo "OSB_SHOULD_PROFILE=${OSB_SHOULD_PROFILE}" >> "${TMP_ENV_PATH}"
}


wait_for_container_stop() {
    local container_name="$1"

    while true; do
        container_status=$(docker inspect --format='{{.State.Running}}' "$container_name" 2>/dev/null)
        if [ "$container_status" != "true" ]; then
            break
        fi
        sleep 5
    done
}

clear_cache() {
    sudo free
    sudo sync
    sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
    sudo free
}