from base-latest

MAINTAINER bearzlh bear.zheng@yunzhihui.com

COPY ./shell /opt
COPY ./modules /data/
WORKDIR /opt

ENV PHP_VERSIONS="5.4.45" \
ZTS_FLAGS="zts nts" \
IF_FPM="1" \
IF_APACHE="1" \
APACHE_VERSION="2.4.23" \
APACHE_FLAG="" \
APR_VERSION="1.6.3" \
APR_UTIL_VERSION="1.6.1" \
NGINX_VERSION="1.14.0"

RUN yum -y install epel-release \
&& yum -y install openssl-devel wget gcc expat-devel zlib-devel make libjpeg-turbo-devel libmcrypt-devel libpng-devel mariadb-devel libxml2 libcurl-devel pcre-devel libxml2-devel autoconf\
&& ./install_apache.sh install \
&& ./install_php.sh install \
&& ./install_nginx.sh install \
&& ./install_module.sh install \
&& rm -rf /opt
