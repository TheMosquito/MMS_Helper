# MMS_Helper a quick and easy way to use the Open-Horizon MMS feature
#
# 1. Begin by installing the Open-Horizon Agent, and configuring your creds:
#   $ agent-install.sh
#   $ export HZN_ORG_ID=...
#   $ export HZN_EXCHANGE_USER_AUTH=...
#
# 2. Edit the Makefile variables below as described:
#   YOUR_SERVICE_NAME - the name of your dependent MMS consumeing Service
#   YOUR_SERVICE_VERSION - the version of your dependent MMS consumeing Service
#   YOUR_OBJECT_TYPE - the object type name for MMS_Helper to monitor
#   YOUR_SHARED_DIR  - host path of the shared directory (volume) for objects
#     Note that you also need to mount this in your Service, e.g., in your
#     Service defiinition's deployment string, use something like this:
#       "binds": ["$YOUR_SHARED_DIR:/CONTAINER_DIR:ro"]
#
# 3. Build, push and publish this "mms-helper" service:
#   $ make build
#   $ docker login -u ...
#   $ make push
#   $ make publish-service
#
# 4. Publish a pattern or business policy to deploy this Service. E.g.:
#   $ make publish-pattern
# 
# 5. Register your edge nodes using a pattern or node policy, e.g.:
#   $ make register-pattern
#
# 6. Start using the `hzn mms object publish` command to publish objects of
# the specified YOUR_OBJECT_TYPE. They will show up up in your /CONTAINER_DIR
# within your container, named using the object IDs you published them with,
# If you used the pattern above, and set the OPTIONAL variables, then:
#   $ make publish-object
# to send the example file object to your dependendency Service running on
# every node registered with the example pattern.

# Please edit these appropriately (as described above)
YOUR_SERVICE_NAME:=mms-user
YOUR_SERVICE_VERSION:=1.0.0
YOUR_OBJECT_TYPE:=myobjecttype
YOUR_SHARED_DIR:=/home/gdarling/objects

# Optionally specify an example file to send as an MMS object. If you do so,
# a file named with the path in OPTIONAL_OBJECT_FILE must be present.
OPTIONAL_OBJECT_ID:=myobject0
OPTIONAL_OBJECT_FILE:=myobject0

# This example is only built for x86
ARCH:=amd64

# Variables for MMS_Helper service/pattern (change for your Docker registry)
MMS_HELPER_SERVICE_NAME:=mms-helper
MMS_HELPER_SERVICE_VERSION:=1.0.0
MMS_HELPER_CONTAINER:=ibmosquito/mms-helper:1.0.0
# For DockerHub, leave the variable below as it is (empty).
# For secure registries set it using:  -r "registry.wherever.com:myid:mypw"`
MMS_HELPER_CONTAINER_CREDS:=
MMS_HELPER_PATTERN_NAME:=mms-helper-pattern

build: Makefile Dockerfile mms_helper.py
	docker build -t $(MMS_HELPER_CONTAINER) .

dev:
	docker run -it -v `pwd`:/outside -v $(YOUR_SHARED_DIR):/shared_dir:rw $(MMS_HELPER_CONTAINER) bin/bash

push:
	docker push $(MMS_HELPER_CONTAINER)

publish-service: validate-creds
	@ARCH=$(ARCH) \
        SERVICE_NAME="$(MMS_HELPER_SERVICE_NAME)" \
        SERVICE_VERSION="$(MMS_HELPER_SERVICE_VERSION)"\
        SERVICE_CONTAINER="$(MMS_HELPER_CONTAINER)" \
        YOUR_SERVICE_NAME="$(YOUR_SERVICE_NAME)" \
        YOUR_SERVICE_VERSION="$(YOUR_SERVICE_VERSION)"\
        YOUR_OBJECT_TYPE="$(YOUR_OBJECT_TYPE)"\
        YOUR_SHARED_DIR="$(YOUR_SHARED_DIR)"\
        hzn exchange service publish -O $(MMS_HELPER_CONTAINER_CREDS) -f service.json

publish-pattern:
	@ARCH=$(ARCH) \
        SERVICE_NAME="$(MMS_HELPER_SERVICE_NAME)" \
        SERVICE_VERSION="$(MMS_HELPER_SERVICE_VERSION)"\
        PATTERN_NAME="$(MMS_HELPER_PATTERN_NAME)" \
	hzn exchange pattern publish -f pattern.json

register-pattern:
	hzn register --pattern "$(MMS_HELPER_PATTERN_NAME)"

publish-object:
	hzn mms object publish --type=$(YOUR_OBJECT_TYPE) --id=$(OPTIONAL_OBJECT_ID) --object=$(OPTIONAL_OBJECT_FILE) --pattern=$(MMS_HELPER_PATTERN_NAME)

validate-creds:
	@if [ -z "${HZN_ORG_ID}" ]; \
          then { echo "***** ERROR: \"HZN_ORG_ID\" is not set!"; exit 1; }; \
          else echo "Using Exchange Org ID: \"${HZN_ORG_ID}\""; \
        fi
	@if [ -z "${HZN_EXCHANGE_USER_AUTH}" ]; \
          then { echo "***** ERROR: \"EXCHANGE_USER_AUTH\" is not set!"; exit 1; }; \
          else echo "Using Exchange user creds: \"${EXCHANGE_USER_AUTH}\""; \
        fi
	@sleep 1

clean:
	-hzn unregister -f
	-hzn exchange service remove -f "${HZN_ORG_ID}/$(MMS_HELPER_SERVICE_NAME)_$(MMS_HELPER_SERVICE_VERSION)_$(ARCH)"
	-docker rmi -f "$(MMS_HELPER_CONTAINER)"

.PHONY: build push publish-service validate-creds test clean
