# syntax=docker/dockerfile:1.4
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software 
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ARG BASE_IMAGE="registry.access.redhat.com/ubi9/ubi-minimal:9.2-691"

ARG AIRFLOW_UID="1001"
ARG AIRFLOW_GID="0"
ARG AIRFLOW_HOME="/opt/airflow"
ARG AIRFLOW_VERSION="2.7.1"
ARG AIRFLOW_OS="rhel9"
ARG AIRFLOW_PYTHON_VERSION="3.11"
ARG AIRFLOW_PIP_VERSION="22.3.1"
ARG AIRFLOW_DATABASE_DRIVER="postgresql"

ARG AIRFLOW_EXTRAS="crypto,celery,redis,postgres,ssh,cncf.kubernetes,statsd"
ARG ADDITIONAL_AIRFLOW_EXTRAS=""
ARG ADDITIONAL_PYTHON_DEPS="dumb-init authlib certifi"

##############################################################################################
# This is the build image where we build all dependencies
##############################################################################################
FROM ${BASE_IMAGE} as airflow-build-image

ARG AIRFLOW_UID
ARG AIRFLOW_GID
ARG AIRFLOW_HOME
ARG AIRFLOW_VERSION
ARG AIRFLOW_OS
ARG AIRFLOW_PYTHON_VERSION
ARG AIRFLOW_PIP_VERSION
ARG AIRFLOW_DATABASE_DRIVER

ARG AIRFLOW_EXTRAS
ARG ADDITIONAL_AIRFLOW_EXTRAS
ARG ADDITIONAL_PYTHON_DEPS

ARG AIRFLOW_GITHUB_REPOSITORY="apache/airflow"
ARG AIRFLOW_CONSTRAINTS_LOCATION=""
ARG AIRFLOW_CONSTRAINTS_REFERENCE=""
ARG AIRFLOW_CONSTRAINTS_BRANCH="constraints-main"


# Minimal set of OS packages required to build Apache Airflow
RUN INSTALL_PKGS="python311 \
                  findutils" && \
    microdnf -y --setopt=tsflags=nodocs --setopt=install_weak_deps=0 install $INSTALL_PKGS && \
    microdnf -y clean all --enablerepo='*'

ENV PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=UTF-8 \
    PIP_NO_CACHE_DIR=off \
    AIRFLOW_VERSION=${AIRFLOW_VERSION} \
    AIRFLOW_HOME=${AIRFLOW_HOME} \
    AIRFLOW_GITHUB_REPOSITORY=${AIRFLOW_GITHUB_REPOSITORY} \
    AIRFLOW_CONSTRAINTS_LOCATION=${AIRFLOW_CONSTRAINTS_LOCATION} \
    AIRFLOW_CONSTRAINTS_REFERENCE=${AIRFLOW_CONSTRAINTS_REFERENCE} \
    AIRFLOW_CONSTRAINTS_BRANCH=${AIRFLOW_CONSTRAINTS_BRANCH} \
    ADDITIONAL_PYTHON_DEPS=${ADDITIONAL_PYTHON_DEPS} \
    PATH=${AIRFLOW_HOME}/bin:$PATH


# - Create a Python virtual environment for use by any application to avoid
#   potential conflicts with Python packages preinstalled in the main Python
#   installation.
RUN \
    python3.11 -m venv ${AIRFLOW_HOME}

# - Copy all install and run scripts to $AIRFLOW_HOME/bin directory
COPY scripts/ $AIRFLOW_HOME/bin/

# - Copy certs
COPY ca.crt /tmp/ca.crt

# - Copy PIP configuration
COPY pip.conf /etc/pip.conf


# - Before runing the install scripts, make them executable
# - Install Airflow from constraints
# - Create dags and logs directories
# - Add additional certs to CA list
RUN \
    chmod a+rx $AIRFLOW_HOME/bin/common.sh $AIRFLOW_HOME/bin/install_airflow.sh && \
    $AIRFLOW_HOME/bin/install_airflow.sh && \
    mkdir -pv "${AIRFLOW_HOME}/dags" && \
    mkdir -pv "${AIRFLOW_HOME}/logs" && \
    cat /tmp/ca.crt >> /opt/airflow/lib/python3.11/site-packages/certifi/cacert.pem


# - The entrypoint and helper scripts must be executable inside containers
# - In order to drop the root user, we have to make some directories world
#   writable as OpenShift default security model is to run the container
#   under random UID.
RUN \
    chmod a+rx $AIRFLOW_HOME/bin/entrypoint.sh $AIRFLOW_HOME/bin/clean-logs.sh $AIRFLOW_HOME/bin/airflow-scheduler-autorestart.sh && \
    chown -R "${AIRFLOW_UID}":"${AIRFLOW_GID}" ${AIRFLOW_HOME} && \
    chmod -R g+rw ${AIRFLOW_HOME} && \
    find "${AIRFLOW_HOME}" -executable -print0 | xargs --null chmod g+x



##############################################################################################
# This is the actual Airflow image - much smaller than the build one. We copy
# installed Airflow and all it's dependencies from the build image to make it smaller.
##############################################################################################
FROM ${BASE_IMAGE}

ARG AIRFLOW_UID
ARG AIRFLOW_GID
ARG AIRFLOW_HOME
ARG AIRFLOW_VERSION
ARG AIRFLOW_OS
ARG AIRFLOW_PYTHON_VERSION
ARG AIRFLOW_PIP_VERSION
ARG AIRFLOW_DATABASE_DRIVER

ARG AIRFLOW_EXTRAS
ARG ADDITIONAL_AIRFLOW_EXTRAS
ARG ADDITIONAL_PYTHON_DEPS


# - Create airflow user and install a minimal set of OS packages
#   to run Apache Airflow
# - Create AIRFLOW_HOME folder with required permission
# - Note: RHEL9/UBI9 packages include PostgreSQL version 13
RUN INSTALL_PKGS="python311 \
                  glibc-langpack-en \
                  git \
                  rsync \
                  findutils \
                  nc \
                  openssh-clients \
                  unixODBC \
                  postgresql" && \
    microdnf -y --setopt=tsflags=nodocs --setopt=install_weak_deps=0 install $INSTALL_PKGS && \
    mkdir -p ${AIRFLOW_HOME} && chmod g+rw ${AIRFLOW_HOME} && \
    microdnf -y clean all --enablerepo='*'


ENV AIRFLOW_PYTHON_VERSION=${AIRFLOW_PYTHON_VERSION} \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    PIP_NO_CACHE_DIR=off \
    AIRFLOW_VERSION=${AIRFLOW_VERSION} \
    AIRFLOW_HOME=${AIRFLOW_HOME} \
    AIRFLOW_GITHUB_REPOSITORY=${AIRFLOW_GITHUB_REPOSITORY} \
    AIRFLOW_CONSTRAINTS_LOCATION=${AIRFLOW_CONSTRAINTS_LOCATION} \
    AIRFLOW_CONSTRAINTS_REFERENCE=${AIRFLOW_CONSTRAINTS_REFERENCE} \
    AIRFLOW_CONSTRAINTS_BRANCH=${AIRFLOW_CONSTRAINTS_BRANCH} \
    ADDITIONAL_PYTHON_DEPS=${ADDITIONAL_PYTHON_DEPS} \
    PATH=${AIRFLOW_HOME}/bin:$PATH


ENV DESCRIPTION="Apache Airflow image running on $AIRFLOW_OS and python $AIRFLOW_PYTHON_VERSION"

LABEL summary="$DESCRIPTION" \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="Apache Airflow image" \
      io.openshift.tags="airflow,rhel,python,python-311,postgresql" \
      name="airflow" \
      version="1"

# - Copy installed Airflow and all it's dependencies from the build image
# - Copy to /opt/ to keep the build image's AIRFLOW_HOME dir permission
COPY --from=airflow-build-image "${AIRFLOW_HOME}" "${AIRFLOW_HOME}"

EXPOSE 8080

USER ${AIRFLOW_UID}

ENTRYPOINT ["dumb-init", "--", "/opt/airflow/bin/entrypoint.sh"]
CMD []

