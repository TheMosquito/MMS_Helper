#
# Begin by installing the Open-Horizon Agent, and configuring your creds:`
#   $ agent-install.sh
#   $ export HZN_ORG_ID=...
#   $ export HZN_EXCHANGE_USER_AUTH=...
#
# Optionally, edit the Makefile variables below as described:
# SERVICE_NAME      - a name of your choice for your open-horizon Service
# SERVICE_VERSION   - version (in format N.N.N) for your open-horizon Service
# SERVICE_CONTAINER - your full container ID (registry/repo:version)
# CONTAINER_CREDS   - optional container read creds (registry/repo:user:token)
# ARCH              - an open-horizon architecture (see `hzn architecture`)
#
# Then build, push and publish this "MMS_Helper" service:
#   $ make build
#   $ docker login -u ...
#   $ make push
#   $ make publish-service
#
# After that your services can add this service as a dependency with:
#
#   "requiredServices": [
#     {
#       "org": "$HZN_ORG_ID",
#       "url": "$SERVICE_NAME",
#       "version": "$SERVICE_VERSION",
#       "arch": "$ARCH"
#     }
#   ]
#   NOTE: the variables above must be set using the values you published!
#

PATTERN_NAME:="pattern-whatever"
SERVICE_NAME:="whatever"
SERVICE_VERSION:="1.0.0"
SERVICE_CONTAINER:="registry.wherever.com/whoever/whatever:version"
CONTAINER_CREDS:=-r "registry.wherever.com:myid:mypw"
ARCH:="amd64"

push:
	@ARCH=$(ARCH) \
        SERVICE_CONTAINER="$(SERVICE_CONTAINER)" \
        docker push $(SERVICE_CONTAINER)

publish-service: validate-creds
	@ARCH=$(ARCH) \
        SERVICE_NAME="$(SERVICE_NAME)" \
        SERVICE_VERSION="$(SERVICE_VERSION)"\
        SERVICE_CONTAINER="$(SERVICE_CONTAINER)" \
        hzn exchange service publish -O $(CONTAINER_CREDS) -f service.json --pull-image

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
	-hzn exchange service remove -f "${HZN_ORG_ID}/$(SERVICE_NAME)_$(SERVICE_VERSION)_$(ARCH)"
	-docker rmi -f "$(SERVICE_CONTAINER)"

.PHONY: push publish-service validate-creds clean

