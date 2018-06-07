#===============================================================================
#
#          FILE: init.sh
#
#         USAGE: ./init.sh
#
#   DESCRIPTION: 启动容器初始化服务
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: bearzlh (https://github.com/bearzlh), bear.zheng@cloudwise.com
#  ORGANIZATION: ChinaCloudwise
#       CREATED: 2018/06/07 12时35分15秒
#      REVISION:  ---
#===============================================================================
#!/bin/sh

path=

chmod +x /etc/rc.d/rc.local

SOFTWARE_DIR=/data/software/

if [ ! -z "$APACHE_VERSION" ] ; then
    $SOFTWARE_DIR/apache/bin/apachectl start
    path="$path:/data/software/apache/bin"
fi

if [ ! -z "$NGINX_VERSION" ] ; then
    $SOFTWARE_DIR/nginx/sbin/nginx
    path="$path:/data/software/nginx/sbin"
fi


if [ ! -z "`ls $SOFTWARE_DIR/php`" ] ; then
    first=`ls $SOFTWARE_DIR/php | sed -n '1p'`
    $SOFTWARE_DIR/php/$first/sbin/php-fpm
fi

if [ ! -z "$path" ] ; then
    source ~/.bashrc
fi

/bin/sh
