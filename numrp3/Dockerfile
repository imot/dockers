FROM php:7.2-fpm-alpine3.8 as php
RUN apk add --no-cache tar
WORKDIR /usr/local
RUN tar -czf /include.tar.gz include

FROM alpine:3.8

MAINTAINER Bayu Irian <bayu.irian@gmail.com>
## Nginx Uwsgi Mysql Runit Php/Postgre/Python = NUMRP3

ENV LANG C.utf8
ENV PGDATA /var/lib/postgresql/data
ENV POSTGRES_PASSWORD "tiger"
ENV ALPINE_PASSWORD "alpine"
ENV PGPORT 5432
ENV ENV="/etc/profile"

EXPOSE 22 3306 5432 80 443

WORKDIR /

RUN echo "Installing package" \
    && apk update \
    && apk add --no-cache \
    dumb-init runit su-exec sudo screen shadow jq \
    curl bash grep gawk bc psmisc logrotate \
    openssl openssh ca-certificates redis \
    libpq postgresql postgresql-contrib postgresql-plpython3 postgresql-plpython3-contrib postgresql-client \
    mysql mysql-client \
    nginx acme-client libressl \
    uwsgi uwsgi-python3 uwsgi-gevent3 uwsgi-logfile uwsgi-syslog uwsgi-http \
    python3 py3-virtualenv py3-pip py3-setuptools \
    # py3-psycopg2 py3-flask py3-sqlalchemy py3-jinja2 py3-lxml py3-curl py3-requests py3-bcrypt py3-six py3-cffi py3-dnspython py3-netifaces \
    pcre2 git \
    && curl -o /usr/local/bin/gosu -sSL "https://github.com/tianon/gosu/releases/download/1.11/gosu-amd64" \
    && chmod +x /usr/local/bin/gosu \
    && adduser -u 1001 -g 1001 -s /bin/bash -D alpine \
    && echo "alpine ALL=NOPASSWD: ALL" > /etc/sudoers.d/alpine \
    && echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su \
    && rm -rf /var/cache/apk/*

RUN apk add --no-cache --virtual .build-deps \
    python3-dev build-base pcre-dev openssl-dev linux-headers libc-dev libffi-dev \
    libintl gettext \
    && cp /usr/bin/envsubst /usr/local/bin/envsubst \
    && yes | pip3 install --no-cache-dir --upgrade pip virtualenvwrapper \
    # && yes | pip3 install --no-cache-dir PyMySQL greenlet gevent asyncio_redis \
    && apk del --force-broken-world .build-deps \
    && rm -rf /var/cache/apk/*

COPY --from=php /usr/local/bin/ /usr/local/bin/
COPY --from=php /usr/local/etc/ /usr/local/etc/
COPY --from=php /usr/local/lib/ /usr/local/lib/
COPY --from=php /usr/local/sbin/ /usr/local/sbin/
COPY --from=php /usr/lib/ /usr/lib/
COPY --from=php /include.tar.gz .

RUN tar -xvzf include.tar.gz -C /usr/local/ \
    && rm -f include.tar.gz \
    && echo "alias build-deps='apk add --no-cache --virtual .build-deps python3-dev build-base pcre-dev openssl-dev linux-headers libc-dev libffi-dev git cmake'" > "/root/.profile" \
    && echo "alias remove-deps='apk del --force-broken-world .build-deps'" >> "/root/.profile" \
    && echo "alias wsgidir='cd /var/www/html/apps'" >> "/root/.profile" \
    # && echo 'PS1="> "' >> "/root/.profile" \
    && echo ". /root/.profile" >> "$ENV" \
    && echo ". $ENV" > "/root/.bashrc"

ENV MEMCACHED_VERSION 1.5.12
ENV MEMCACHED_SHA1 f67096ba64b0c47668bcad5b680010c4f8987d4c

RUN addgroup -g 11211 memcache \
    && adduser -D -u 11211 -G memcache memcache \
    # && addgroup -g 82 -S www-data \
    && adduser -u 82 -D -S -G www-data www-data \
    && set -x \
    && apk add --no-cache --force-broken-world --virtual .build-deps \
    ca-certificates coreutils cyrus-sasl-dev dpkg-dev dpkg gcc libc-dev libevent-dev libressl linux-headers make perl perl-utils \
    && wget -O memcached.tar.gz "https://memcached.org/files/memcached-$MEMCACHED_VERSION.tar.gz" \
    && echo "$MEMCACHED_SHA1 memcached.tar.gz" | sha1sum -c - \
    && mkdir -p /usr/src/memcached \
    && tar -xzf memcached.tar.gz -C /usr/src/memcached --strip-components=1 \
    && rm memcached.tar.gz \
    && cd /usr/src/memcached \
    && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
    && enableExtstore="$( case "$gnuArch" in s390x-*) ;; *) echo '--enable-extstore' ;; esac )" \
    && ./configure --build="$gnuArch" --enable-sasl $enableExtstore \
    && make -j "$(nproc)" \
    # && make test \
    && make install \
    && cd / && rm -rf /usr/src/memcached \
    && runDeps="$( scanelf --needed --nobanner --format '%n#p' --recursive /usr/local | tr ',' '\n' | sort -u | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' )" \
    && apk add --virtual .memcached-rundeps $runDeps \
    && apk del .build-deps \
    && memcached -V

COPY runit/ /opt/numrp3/runit/
COPY build/ /opt/numrp3/build/
COPY build/my.cnf /etc/mysql/
COPY build/service_setup.sh /opt/init/init.sh
COPY build/acme-run.sh /etc/periodic/weekly/acme-run.sh

VOLUME /etc/uwsgi/conf.d
VOLUME /etc/ssh
VOLUME /etc/nginx/conf.d
VOLUME /etc/mysql/conf.d
VOLUME /var/lib/postgresql/data
VOLUME /var/lib/mysql
VOLUME /var/www/html

# HEALTHCHECK --interval=5m --timeout=3s CMD curl -f http://localhost/ || exit 1

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/bin/bash", "-c", "/opt/init/init.sh && /sbin/runsvdir -P /etc/service"]
