FROM ubuntu:bionic

RUN apt-get update --yes
RUN apt-get install --yes --no-install-recommends \
                                                  mime-support
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

ENV IMAGE_NAME modsecurity-build
ENV DOCKER_RO_DIR /src.d
ENV DOCKER_RW_DIR /dst.d

ENV APACHE_BUILD_DIR /httpd
ENV APACHE_TARGZ httpd-2.4.41.tar.gz
ENV APACHE_APR_TARGZ apr-1.7.0.tar.gz
ENV APACHE_APR_UTIL_TARGZ apr-util-1.6.1.tar.gz
ENV MODSECURITY_BUILD_DIR /modsecurity
ENV MODSECURITY_TARGZ modsecurity-2.9.3.tar.gz

VOLUME ${DOCKER_RO_DIR}
VOLUME ${DOCKER_RW_DIR}

WORKDIR /

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

ENTRYPOINT ${DOCKER_RO_DIR}/doit.sh
