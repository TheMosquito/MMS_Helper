all: build publish-service

build:
	docker build -t ibmosquito/mms-user:1.0.0 .

dev:
	docker run -it ibmosquito/mms-user:1.0.0 /bin/sh

push:
	docker push ibmosquito/mms-user:1.0.0

publish-service:
	hzn exchange service publish -O -f service.json

