#!/usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
# shellcheck shell=bash
set -euo pipefail

function get_colors() {
    COLOR_BLUE=$'\e[34m'
    COLOR_GREEN=$'\e[32m'
    COLOR_RED=$'\e[31m'
    COLOR_RESET=$'\e[0m'
    COLOR_YELLOW=$'\e[33m'
    export COLOR_BLUE
    export COLOR_GREEN
    export COLOR_RED
    export COLOR_RESET
    export COLOR_YELLOW
}

function get_constraints_location() {
    # auto-detect Airflow-constraint reference and location
    if [[ -z "${AIRFLOW_CONSTRAINTS_REFERENCE=}" ]]; then
        if  [[ ${AIRFLOW_VERSION} =~ v?2.* && ! ${AIRFLOW_VERSION} =~ .*dev.* ]]; then
            AIRFLOW_CONSTRAINTS_REFERENCE=constraints-${AIRFLOW_VERSION}
        else
            AIRFLOW_CONSTRAINTS_REFERENCE=${AIRFLOW_CONSTRAINTS_BRANCH}
        fi
    fi

    if [[ -z "${AIRFLOW_CONSTRAINTS_LOCATION=}" ]]; then
        local constraints_base="https://raw.githubusercontent.com/${AIRFLOW_GITHUB_REPOSITORY}/${AIRFLOW_CONSTRAINTS_REFERENCE}"
        local python_version
        python_version="$(python --version 2>/dev/stdout | cut -d " " -f 2 | cut -d "." -f 1-2)"
        AIRFLOW_CONSTRAINTS_LOCATION="${constraints_base}/constraints-${python_version}.txt"
    fi
}

function show_pip_version_and_location() {
   echo "PATH=${PATH}"
   echo "pip on path: $(whereis pip)"
   echo "Using pip: $(pip --version)"
}

function install_pip_version() {
    echo
    echo "${COLOR_BLUE}Installing pip version ${AIRFLOW_PIP_VERSION}${COLOR_RESET}"
    echo
    if [[ ${AIRFLOW_PIP_VERSION} =~ .*https.* ]]; then
        pip install --disable-pip-version-check --no-cache-dir "pip @ ${AIRFLOW_PIP_VERSION}"
    else
        pip install --disable-pip-version-check --no-cache-dir "pip==${AIRFLOW_PIP_VERSION}"
    fi
}