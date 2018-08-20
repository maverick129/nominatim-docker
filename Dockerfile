FROM ubuntu:16.04

MAINTAINER Marc Helbling <marc@helbling.fr>

ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8
ENV NOMINATIM_VERSION v3.1.0

RUN apt-get -y update -qq \
 && apt-get -y install locales \
 && locale-gen en_US.UTF-8 \
 && update-locale LANG=en_US.UTF-8 \
 && apt-get install -y \
        build-essential \
        cmake \
        g++ \
        libboost-dev \
        libboost-system-dev \
        libboost-filesystem-dev \
        libexpat1-dev \
        zlib1g-dev \
        libxml2-dev\
        libbz2-dev \
        libpq-dev \
        libgeos-dev \
        libgeos++-dev \
        libproj-dev \
        postgresql-server-dev-9.5 \
        postgresql-9.5-postgis-2.2 \
        postgresql-contrib-9.5 \
        apache2 \
        php \
        php-pgsql \
        libapache2-mod-php \
        php-pear \
        php-db \
        php-intl \
        git \
        curl \
        sudo \
        python-pip \
        libboost-python-dev \
        osmosis \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /tmp/* /var/tmp/*

WORKDIR /app

# Configure postgres
RUN echo "host all  all    0.0.0.0/0  trust" >> /etc/postgresql/9.5/main/pg_hba.conf \
 && echo "listen_addresses='*'" >> /etc/postgresql/9.5/main/postgresql.conf \

 # Nominatim install
 && git clone --recursive https://github.com/openstreetmap/Nominatim ./src \
 && cd ./src \
 && git checkout tags/$NOMINATIM_VERSION \
 && git submodule update --recursive --init \
 && mkdir build \
 && cd build \
 && cmake .. \
 && make -j4 \

 # Osmium install to run continuous updates
 && pip install osmium \

 # Load initial data
 && curl http://www.nominatim.org/data/country_grid.sql.gz > /app/src/data/country_osm_grid.sql.gz

# Apache configure
COPY conf/local.php /app/src/build/settings/local.php
COPY conf/nominatim.conf /etc/apache2/sites-enabled/000-default.conf

# helper scripts
COPY scripts/start.sh         /app/start.sh
COPY scripts/startapache.sh   /app/startapache.sh
COPY scripts/startpostgres.sh /app/startpostgres.sh
COPY scripts/init.sh          /app/init.sh

EXPOSE 5432
EXPOSE 8080
