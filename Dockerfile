FROM technicalguru/rs-php:7.4.24-apache-2.4.48.1
LABEL maintainer="Ralph Schuster <github@ralph-schuster.eu>"

ENV DKIM_VERSION="2.11.0"
ENV DKIM_REVISION="0"
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install -y --no-install-recommends \
    wget \
    opendkim=2.11.0~beta2-4 \
    opendkim-tools=2.11.0~beta2-4 \
    libopendbx1-mysql \
    default-mysql-client \
	vim \
    rsyslog \
    dnsutils \
    && rm -rf /var/lib/apt/lists/*

#ADD etc/php/ /usr/local/etc/php/conf.d/
#ADD etc/conf/ /etc/apache2/conf-enabled/
#ADD etc/mods/ /etc/apache2/mods-enabled/
#ADD etc/sites/ /etc/apache2/sites-enabled/
#ADD src/    /var/www/html/

RUN mkdir /usr/local/mailserver \
    && mkdir /usr/local/mailserver/templates \
    && mkdir /usr/local/mailserver/templates/default \
    && mkdir /etc/opendkim \
    && mkdir /etc/opendkim/keys \
    && rm /etc/opendkim.conf /etc/default/opendkim


ADD src/ /usr/local/mailserver/
ADD etc/ /usr/local/mailserver/templates/

RUN chmod 755 /usr/local/mailserver/*.sh \
    && chown -R www-data:www-data /etc/opendkim \
    && chown -R www-data:www-data /var/www/html

EXPOSE 41001
EXPOSE 80

#CMD ["/usr/local/mailserver/loop.sh"]
CMD ["/usr/local/mailserver/entrypoint.sh"]

#####################################################################
#  Image OCI labels
#####################################################################
ARG ARG_CREATED
ARG ARG_URL=https://github.com/technicalguru/docker-mailserver-dkim
ARG ARG_SOURCE=https://github.com/technicalguru/docker-mailserver-dkim
ARG ARG_VERSION="${DKIM_VERSION}.${DKIM_REVISION}"
ARG ARG_REVISION="${DKIM_REVISION}"
ARG ARG_VENDOR=technicalguru
ARG ARG_TITLE=technicalguru/mailserver-dkim
ARG ARG_DESCRIPTION="Provides DKIM signing for Postfix server"
ARG ARG_DOCUMENTATION=https://github.com/technicalguru/docker-mailserver-dkim
ARG ARG_AUTHORS=technicalguru
ARG ARG_LICENSES=GPL-3.0-or-later

LABEL org.opencontainers.image.created=$ARG_CREATED
LABEL org.opencontainers.image.url=$ARG_URL
LABEL org.opencontainers.image.source=$ARG_SOURCE
LABEL org.opencontainers.image.version=$ARG_VERSION
LABEL org.opencontainers.image.revision=$ARG_REVISION
LABEL org.opencontainers.image.vendor=$ARG_VENDOR
LABEL org.opencontainers.image.title=$ARG_TITLE
LABEL org.opencontainers.image.description=$ARG_DESCRIPTION
LABEL org.opencontainers.image.documentation=$ARG_DOCUMENTATION
LABEL org.opencontainers.image.authors=$ARG_AUTHORS
LABEL org.opencontainers.image.licenses=$ARG_LICENSES

