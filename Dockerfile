FROM ubuntu:bionic

RUN apt-get update --yes
RUN apt-get install --yes --no-install-recommends gcc make flex bison bc patch
RUN apt-get install --yes --no-install-recommends \
                                                  libc6-dev \
                                                  libcurl4 \
                                                  libcurl4-openssl-dev \
                                                  apache2-dev \
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
ENV MODSECURITY_BUILD_DIR /modsecurity
ENV MODSECURITY_TARGZ modsecurity-2.9.3.tar.gz
ENV DOCKER_RO_DIR /src.d
ENV DOCKER_RW_DIR /dst.d

VOLUME ${DOCKER_RO_DIR}
VOLUME ${DOCKER_RW_DIR}

RUN mkdir ${MODSECURITY_BUILD_DIR}
COPY ${MODSECURITY_TARGZ} ${MODSECURITY_BUILD_DIR}
WORKDIR ${MODSECURITY_BUILD_DIR}
RUN { \
            set -u -e -x; \
            tar -x -f "${MODSECURITY_TARGZ}"; \
            cd "${MODSECURITY_TARGZ%.tar.gz}"; \
            ./configure; \
            nr_cpus="$(grep -c '^processor' /proc/cpuinfo)"; \
            if test "$nr_cpus" -gt "1"; then \
                nr_threads="$(($nr_cpus >> 1))"; \
            else \
                nr_threads="$nr_cpus"; \
            fi; \
            make "-j${nr_threads}"; \
    }

ENTRYPOINT ${DOCKER_RO_DIR}/doit.sh
