all: build publish-service

DOCKERHUB_ID:=ibmosquito

build:
	docker build -t $(DOCKERHUB_ID)/my_example_consumer:1.0.0 .

dev:
	docker run -it $(DOCKERHUB_ID)/my_example_consumer:1.0.0 /bin/sh

push:
	docker push $(DOCKERHUB_ID)/my_example_consumer:1.0.0

publish-service:
	hzn exchange service publish -O -f service.json

