FROM ubuntu:22.04

RUN sed -i -e 's/# deb-src/deb-src/' /etc/apt/sources.list
RUN apt-get update
RUN apt-get install python3-pip -y
RUN apt-get install build-essential git zlib1g-dev -y
RUN ln -snf /usr/share/zoneinfo/America/Phoenix /etc/localtime && echo America/Phoenix > /etc/timezone
RUN apt-get build-dep openssl -y
RUN pip3 install --upgrade pip setuptools wheel
RUN pip3 install --upgrade sslyze
ENTRYPOINT ["python3","-m","sslyze"]
