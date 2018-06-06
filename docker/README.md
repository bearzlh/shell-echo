##脚本说明
```
from base-latest

MAINTAINER bearzlh bear.zheng@yunzhihui.com

#copy shell command dir to /opt of image
COPY ./shell /opt

#copy php modules dir,auto installed
COPY ./modules /data/

#shell executed dir as docker building
WORKDIR /opt

#following is settings
################################################
#which php version will be installed,splited by space
ENV PHP_VERSIONS="5.4.45" \

#zts flags,splited by space
ZTS_FLAGS="zts nts" \

#if compiled with php-fpm,disabled by empty string
IF_FPM="1" \

#if compiled with apache,diabled by empty string
IF_APACHE="1" \

#not to install by empty string
APACHE_VERSION="2.4.23" \

#it will append apache configure flags
APACHE_FLAG="" \

#for apache dependency,leave it the value when not sure
APR_VERSION="1.6.3" \

#for apache dependency,leave it the value when not sure
APR_UTIL_VERSION="1.6.1" \

#not to install by empty string
NGINX_VERSION="1.14.0"
################################################


#commands to execute,you should not care about
RUN yum -y install epel-release \
&& yum -y install openssl-devel wget gcc expat-devel zlib-devel make libjpeg-turbo-devel libmcrypt-devel libpng-devel mariadb-devel libxml2 libcurl-devel pcre-devel libxml2-devel autoconf\
&& ./install_apache.sh install \
&& ./install_php.sh install \
&& ./install_nginx.sh install \
&& ./install_module.sh install \
&& rm -rf /opt
```
