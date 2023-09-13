# Image URL to use all building/pushing image targets
REGISTRY ?= quay.io
REPOSITORY ?= $(REGISTRY)/modast

BASE_IMAGE_TAG ?= 9.2-717
BASE_IMAGE ?= registry.access.redhat.com/ubi9/ubi-minimal:$(BASE_IMAGE_TAG)

AIRFLOW_VERSION ?= 2.7.1
AIRFLOW_IMAGE := $(REPOSITORY)/airflow:v$(AIRFLOW_VERSION)

podman-login:
	@podman login -u $(DOCKER_USER) -p $(DOCKER_PASSWORD) $(REGISTRY)

podman-build-airflow:
	podman build --build-arg BASE_IMAGE=$(BASE_IMAGE) --build-arg AIRFLOW_VERSION=$(AIRFLOW_VERSION) . -t ${AIRFLOW_IMAGE} -f Dockerfile

podman-push-airflow: podman-build-airflow
	podman push ${AIRFLOW_IMAGE}

build: podman-build-airflow

push: podman-push-airflow