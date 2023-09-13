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

. "$( dirname "${BASH_SOURCE[0]}" )/common.sh"

function install_airflow() {
        echo
        echo "${COLOR_BLUE}Installing all packages with constraints and upgrade if needed${COLOR_RESET}"
        echo
        set -x
        pip install --root-user-action ignore "apache-airflow[${AIRFLOW_EXTRAS}]==${AIRFLOW_VERSION}" \
            --constraint "${AIRFLOW_CONSTRAINTS_LOCATION}"
        # then upgrade if needed without using constraints to account for new limits in setup.py
        pip install --root-user-action ignore --upgrade --upgrade-strategy only-if-needed \
            "apache-airflow[${AIRFLOW_EXTRAS}]==${AIRFLOW_VERSION}"
        set +x
        echo
        echo "${COLOR_BLUE}Running 'pip check'${COLOR_RESET}"
        echo
        pip check

}

function install_additional_dependencies() {
    echo
    echo "${COLOR_BLUE}Installing additional dependencies upgrading only if needed${COLOR_RESET}"
    echo
    set -x
    pip install --root-user-action ignore --upgrade --upgrade-strategy only-if-needed ${ADDITIONAL_PYTHON_DEPS}
    set +x
    echo
    echo "${COLOR_BLUE}Running 'pip check'${COLOR_RESET}"
    echo
    pip check
}

get_colors
get_constraints_location
install_pip_version
show_pip_version_and_location

install_airflow
install_additional_dependencies