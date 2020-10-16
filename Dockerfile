FROM ubuntu:18.04

RUN apt update && apt install -y python3 python3-pip

COPY ./mms_helper.py /
WORKDIR /

CMD python3 mms_helper.py

