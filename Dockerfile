FROM python:2.7-alpine

MAINTAINER thomas.monguillon "thomas.monguillon@orange.com"

ARG REQUIREMENTS_BRANCH=master
ENV REQUIREMENTS_BRANCH $REQUIREMENTS_BRANCH

ARG KEYSTONE_BRANCH=master
ENV KEYSTONE_BRANCH $KEYSTONE_BRANCH

ENV VERSION=1.0.0

WORKDIR /opt

RUN apk add --no-cache \
    bash \
    wget \
    curl \
    libffi \
    libxslt \
    mariadb-client

# Install build-deps, pip install packages and clean deps (to keep image small)
RUN apk add --no-cache --virtual build-deps \
    git \
    gcc \
    linux-headers \
    libc-dev \
    python-dev \
    openssl-dev \
    libffi-dev \
    mariadb-dev \
    && git clone --branch $KEYSTONE_BRANCH --depth=1 https://github.com/openstack/requirements \
    && git clone --branch $KEYSTONE_BRANCH --depth=1 https://github.com/openstack/keystone \
#    && git clone --branch $KEYSTONE_BRANCH --depth=1 https://github.com/openstack/python-keystoneclient \
    && git clone --branch $KEYSTONE_BRANCH --depth=1 https://github.com/openstack/python-openstackclient \
    && pip install ./requirements \
    && pip install ./keystone -c ./requirements/upper-constraints.txt \
#    && pip install ./python-keystoneclient \
    && pip install ./python-openstackclient -c ./requirements/global-requirements.txt \
    && pip install uwsgi MySQL-python pymysql pymysql_sa \
    && cp -r ./keystone/etc /etc/keystone \
    && rm -rf /root/.cache
#    && rm -rf /opt/* 
#    && apk del build-deps


COPY keystone.conf /etc/keystone/keystone.conf
COPY keystone.sql /root/keystone.sql

# Add bootstrap script and make it executable
COPY bootstrap.sh /etc/bootstrap.sh
COPY bootstrapv2.sh /etc/bootstrapv2.sh
RUN chown root:root /etc/bootstrap*.sh && chmod a+x /etc/bootstrap*.sh

#ENTRYPOINT ["/etc/bootstrap.sh"]
#CMD ["/etc/bootstrap.sh"]
CMD ["tail", "-f", "/dev/null"]
EXPOSE 5000 35357

#HEALTHCHECK --interval=10s --timeout=5s \
#  CMD curl -f http://localhost:5000/v3 2> /dev/null || exit 1; \
#  curl -f http://localhost:35357/v3 2> /dev/null || exit 1; \
