FROM ubuntu:bionic

MAINTAINER Nikita Popov <npv1310_at_gmail.com>

RUN apt-get update --yes
RUN apt-get install --yes --no-install-recommends \
                                                  mime-support \
                                                  adduser
RUN apt-get install --yes --no-install-recommends \
                                                  xz-utils \
                                                  make \
                                                  gcc \
                                                  flex \
                                                  bison \
                                                  bc \
                                                  patch \
                                                  gawk \
                                                  python3 \
                                                  file
RUN apt-get install --yes --no-install-recommends \
                                                  libc6-dev \
                                                  libexpat1 \
                                                  libexpat1-dev \
                                                  libssl1.1 \
                                                  libssl-dev \
                                                  libelf1 \
                                                  libelf-dev \
                                                  libcurl4 \
                                                  libcurl4-openssl-dev \
                                                  libpcre3 \
                                                  libpcre3-dev \
                                                  libxml2 \
                                                  libxml2-dev \
                                                  liblua5.3-0 \
                                                  liblua5.3-dev \
                                                  libyajl2 \
                                                  libyajl-dev \
                                                  libfuzzy2 \
                                                  libfuzzy-dev

ENV IMAGE_NAME web-protection-env
ENV HOST_NAME ${IMAGE_NAME}.local
ENV DOCKER_RO_DIR /sources
ENV DOCKER_RW_DIR /www

ENV APACHE_BUILD_DIR /httpd-build
ENV APACHE_TARGZ httpd-2.4.41.tar.gz
ENV APACHE_APR_TARGZ apr-1.7.0.tar.gz
ENV APACHE_APR_UTIL_TARGZ apr-util-1.6.1.tar.gz
ENV MODSECURITY_BUILD_DIR /modsecurity-build
ENV MODSECURITY_TARGZ modsecurity-2.9.3.tar.gz

ENV CONFIG_TEMPLATE ${DOCKER_RO_DIR}/modsecurity-aware.conf.tpl

# APACHE config files parameters. These are substituted in .conf.tpl file
ENV SERVER_NAME http://${HOST_NAME}:80
ENV SERVER_ROOT ${DOCKER_RW_DIR}
ENV SERVER_PID_FILE httpd.pid
ENV SERVER_USER www-user
ENV SERVER_GROUP www-user
# It's important to keep DOCROOT absolute, since it is used in <directory> section
ENV SERVER_DOCROOT ${SERVER_ROOT}/docs
ENV SERVER_ERROR_LOG errors.log
ENV SERVER_ACCESS_LOG accesses.log

ENV MODSECURITY_CONFIG ${SERVER_ROOT}/security_rules.conf

VOLUME ${DOCKER_RO_DIR}
VOLUME ${DOCKER_RW_DIR}

WORKDIR /

RUN addgroup --quiet  \
             --system \
             "${SERVER_GROUP}"
RUN adduser  --quiet                     \
             --shell "/usr/sbin/nologin" \
             --no-create-home            \
             --system                    \
             --ingroup "${SERVER_GROUP}" \
             --home "${SERVER_ROOT}"     \
             "${SERVER_USER}"

RUN mkdir ${APACHE_BUILD_DIR}
COPY ${APACHE_TARGZ} ${APACHE_BUILD_DIR}
COPY ${APACHE_APR_TARGZ} ${APACHE_BUILD_DIR}
COPY ${APACHE_APR_UTIL_TARGZ} ${APACHE_BUILD_DIR}
RUN { \
            set -u -e -x; \
            cd "${APACHE_BUILD_DIR}"; \
            tar -x -f "${APACHE_TARGZ}"; \
            cd "${APACHE_TARGZ%.tar.gz}/srclib"; \
            tar -x -f "${APACHE_BUILD_DIR}/${APACHE_APR_TARGZ}"; \
            mv "${APACHE_APR_TARGZ%.tar.gz}" "apr"; \
            tar -x -f "${APACHE_BUILD_DIR}/${APACHE_APR_UTIL_TARGZ}"; \
            mv "${APACHE_APR_UTIL_TARGZ%.tar.gz}" "apr-util"; \
            cd ".."; \
            ./configure --prefix="/usr/apache2" \
                        --enable-pie \
                        --enable-mods-static="reallyall" \
                        --with-mpm=prefork \
                        --disable-cgid \
                        --disable-example-hooks \
                        --disable-example-ipc \
                        --disable-optional-hook-export \
                        --disable-optional-hook-import \
                        --disable-optional-fn-import \
                        --disable-optional-fn-export \
                        --with-crypto; \
            nr_cpus="$(grep -c '^processor' /proc/cpuinfo)"; \
            if test "$nr_cpus" -gt "1"; then \
                nr_threads="$(($nr_cpus >> 1))"; \
            else \
                nr_threads="$nr_cpus"; \
            fi; \
            make "-j${nr_threads}"; \
            make install; \
    }

RUN mkdir ${MODSECURITY_BUILD_DIR}
COPY ${MODSECURITY_TARGZ} ${MODSECURITY_BUILD_DIR}
RUN { \
            set -u -e -x; \
            cd "${MODSECURITY_BUILD_DIR}"; \
            tar -x -f "${MODSECURITY_TARGZ}"; \
            cd "${MODSECURITY_TARGZ%.tar.gz}"; \
            ./configure --prefix="/usr/modsecurity" \
                        --enable-apache2-module \
                        --enable-extentions \
                        --with-apxs="/usr/apache2/bin/apxs" \
                        --with-apr="/usr/apache2/bin/apr-1-config" \
                        --with-apu="/usr/apache2/bin/apu-1-config"; \
            nr_cpus="$(grep -c '^processor' /proc/cpuinfo)"; \
            if test "$nr_cpus" -gt "1"; then \
                nr_threads="$(($nr_cpus >> 1))"; \
            else \
                nr_threads="$nr_cpus"; \
            fi; \
            make "-j${nr_threads}"; \
            make install; \
    }

EXPOSE 80

ENTRYPOINT ${DOCKER_RO_DIR}/doit.sh
