This folder contains Dockerfiles and scripts for building Apache Airflow images from [Red Hat minimal UBI image](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html-single/building_running_and_managing_containers/index#con_understanding-the-ubi-minimal-images_assembly_types-of-container-images).

### Dockerfile highlights:
* Uses [Red Hat Universal Base Image 9 Minimal](https://catalog.redhat.com/software/containers/ubi9/ubi-minimal/615bd9b4075b022acc111bf5) as the base build image.
* Instead of using a [UBI python image](https://catalog.redhat.com/software/containers/ubi9/python-311/63f764b03f0b02a2e2d63fff), it installs Python 3.11 on top of ubi9/ubi-minimal to keep the final image as lean as possible.
* Employs a multi-stage build to reduce the final image size. (~180 MiB compressed with baseline airflow providers)
* Leverages "known-to-be-working" constraint files to install Airflow and its dependencies from PyPI.
* Installs PostgreSQL driver libraries for the default database.
* Uses [podman](https://podman.io/) to build and push images.

### Manual Build on Your Local Machine
#### Prerequisites
* Linux machine
* [podman](https://podman.io/)

#### Build Image

1. Clone the GitHub repository to an empty folder on your local machine:
    ```bash
    git clone https://github.com/aszmuda/mds-supply-chain.git
    ```
2. Change into the `airflow` directory
3. Open the `Makefile` and override the env variables according to your needs. For example:
    ```bash
    REGISTRY ?= quay.io
    REPOSITORY ?= $(REGISTRY)/modast
    
    BASE_IMAGE_TAG ?= 9.2-717
    BASE_IMAGE ?= registry.access.redhat.com/ubi9/ubi-minimal:$(BASE_IMAGE_TAG)
    
    AIRFLOW_VERSION ?= 2.7.1
    AIRFLOW_IMAGE := $(REPOSITORY)/airflow:$(AIRFLOW_VERSION)
    ```
 > **Note:** For complex changes (i.e. python version, additional rpms, etc.) you should modify the `Dockerfile`

4. Build the image:
    ```bash
    make build
    ```
#### Push image
1. Login to you registry and run:
   ```bash
   make push
   ```

### Build on push using GitHub Actions
The repository contains a sample workflow to build/push the Airflow image. Everytime you push a change under the `aiflow/**` path, a new workflow run is started.</br>

#### Build prerequisites:
1. Fork this repository
2. In your forked repository, create the `REGISTRY_USER` and `REGISTRY_PASSWORD` secretes for storing your Docker registry login details.
3. Open the `.github/workflows/build-push-airflow.yaml` and override the global env variables as you need:
```bash
env:
   REGISTRY: quay.io
   REPOSITORY: modast
   BASE_IMAGE: registry.access.redhat.com/ubi9/ubi-minimal
   BASE_IMAGE_TAG: 9.2-717
   AIRFLOW_VERSION: 2.7.1
```
4. Commit and push your changes to GitHub to start a new build.

### Other configurations
#### PIP configuration
In order to install python packages from your private PyPI registry instead of the default public, modify the content of `pip.conf`

#### Custom CA certificates
If you need to include your own CA certs in the final image, replace the content of the `ca.crt` with the relevant certificates.