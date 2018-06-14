#===============================================================================
#
#          FILE: install_module.sh
#
#         USAGE: ./install_module.sh
#
#   DESCRIPTION: 
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Bear.Zheng (https://github.com/bearzlh), bear.zheng@cloudwise.com
#  ORGANIZATION: ChinaCloudwise
#       CREATED: 2018年06月01日 04时36分22秒
#      REVISION:  ---
#===============================================================================
#!/bin/sh
#自动将php扩展复制到php源码的扩展目录，并执行编译
#main functions
source ./main.sh

#log file
LOG=/data/log/module_install

check_libs "epel-release jq psmisc autoconf gcc make libcurl-devel"

#test_api='http://dev.admin.com:port/admin/student/index?sort=id&order=desc&offset=0&limit=10&_=1527844738037'
test_api='http://dev.admin.com:port/demo.php'

#php source dir
PHP_SRC_DIR=/data/src/php/

#php installed dir
PHP_SOFTWARE_DIR=/data/software/php/

#extension source dir
MODULE_DIR=/opt/modules/

if [ -z "`cat /etc/hosts | grep fastadmin`" ] ; then
    exec_cmd 'echo 10.0.2.230 fastadmin >> /etc/hosts'
    exec_cmd 'echo 127.0.0.1 dev.admin.com >> /etc/hosts'
fi

APACHE_VHOST_PATH=/data/software/apache/conf/extra/

if [ -d "$APACHE_VHOST_PATH" ] ; then
    for host in `ls $APACHE_VHOST_PATH`; do
        if [ ! -z "`cat $APACHE_VHOST_PATH$host | grep '\/test\/'`" ] ; then
            exec_cmd "sed -i 's#/test/#/fastadmin/public/#' $APACHE_VHOST_PATH$host"
        fi
    done
fi

NGINX_VHOST_PATH=/data/software/nginx/conf/vhost/

if [ -d "$NGINX_VHOST_PATH" ] ; then
    for host in `ls $NGINX_VHOST_PATH`; do
        if [ ! -z "`cat $NGINX_VHOST_PATH$host | grep '\/test\/'`" ] ; then
            exec_cmd "sed -i 's#/test/#/fastadmin/public/#' $NGINX_VHOST_PATH$host"
        fi
    done
fi


if [ ! -d "/data/log/phpagent/" ] ; then
    exec_cmd "mkdir -p /data/log/phpagent/"
    exec_cmd "touch /data/log/phpagent/trace_data.json"
    exec_cmd "chmod -R 777 /data/log"
fi

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  check_version
#   DESCRIPTION:  dump which version to install
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
check_version ()
{
    log "deal as follows"
    #param process
    filter_module="$1"
    filter_php="$2"

    #extension filter
    if [ -d $MODULE_DIR -a ! -z "filter_module" ];then
        MODULE_NAMES=`ls $MODULE_DIR|grep -E "^$filter_module$"`
    fi

    grep_version=
    grep_zts=

    #version and zts filter
    if [ ! -z "$filter_php" ];then
        if [ -z "`echo $filter_php | grep '-'`" ];then
            grep_version=$filter_php
        else
            grep_version=`echo $filter_php|cut -d '-' -f1`
            grep_zts=`echo $filter_php|cut -d '-' -f2`
        fi
    fi

    #filter php and zts type
    PHP_SOFTWARE_LIST=`ls $PHP_SOFTWARE_DIR | grep "$grep_version" | grep "$grep_zts"`

    for php in $PHP_SOFTWARE_LIST
    do
        module_names=$MODULE_NAMES
        version=`echo $php|cut -d '_' -f1`
        php_dir=${PHP_SRC_DIR}php-${version}/
        php_software_dir=$PHP_SOFTWARE_DIR$php/
        php_ext_dir=${php_dir}ext/

        if [ -z $module_names ] ; then
            module_names=`ls $php_ext_dir | grep -E "$filter_module"`
        fi
        info "$php:`echo $module_names | xargs`"
    done
}	# ----------  end of function check_version  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  install
#   DESCRIPTION:  module install
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
install(){
    #param process
    filter_module="smart_agent"

    #extension filter
    if [ -d $MODULE_DIR -a ! -z "filter_module" ];then
        MODULE_NAMES=`ls $MODULE_DIR|grep -E "^$filter_module$"`
    fi

    PHP_SOFTWARE_LIST=`ls $PHP_SOFTWARE_DIR`

    for php in $PHP_SOFTWARE_LIST
    do
        log "install for $php"

        module_names=$MODULE_NAMES
        version=`echo $php|cut -d '_' -f1`
        php_dir=${PHP_SRC_DIR}php-${version}/
        php_software_dir=$PHP_SOFTWARE_DIR$php/
        php_ext_dir=${php_dir}ext/


        if [ ! -d "$php_ext_dir" ] ; then
            exec_cmd "mkdir -p $php_ext_dir"
        fi

        if [ -z "$module_names" ] ; then
            module_names=`ls $php_ext_dir | grep -E "$filter_module"`
        else
            for check_module in $module_names; do
                if [ -d "$php_ext_dir$check_module" ] ; then
                    exec_cmd "rm -rf $php_ext_dir$check_module"
                fi

                exec_cmd "cp -r $MODULE_DIR$check_module $php_ext_dir$check_module"
            done
        fi


        if [ -z "$module_names" ] ; then
            error "module names not found;continue"
            continue
        fi

        #traversal extension dirs
        for MODULE_NAME in $module_names
        do
            (
                php_module_dir=$php_ext_dir$MODULE_NAME

                exec_cmd "cd $php_module_dir"

                make distclean >> /dev/null 2>&1

                exec_cmd "${php_software_dir}bin/phpize"

                exec_cmd "./configure --with-php-config=${php_software_dir}bin/php-config"

                #gdb debug
                exec_cmd "sed -i 's/-g /-g3 -gdwarf-2 /g' Makefile"

                exec_cmd "make"
                
                exec_cmd "make install"

                ini_file=`${php_software_dir}bin/php --ini | sed -n '2p'|awk '{print $NF}'`

                #check php.ini
                exec_cmd "[ -f  $ini_file ]"

                #remove old config
                exec_cmd "sed -i -e "/$MODULE_NAME/d" $ini_file"

                #add timezone if empty
                if [ -z `cat $ini_file|grep "^date.timezone"|cut -d '=' -f2` ];then
                    exec_cmd "sed -i 's/;date.timezone.*/date.timezone=PRC/' $ini_file"
                fi

                #add config from file init.tpl if the file exists otherwise add so config only
                if [ -f init.tpl ];then
                    exec_cmd "sed -i '\$r init.tpl' $ini_file"
                else
                    exec_cmd "sed -i -e '\$a'extension=${MODULE_NAME}.so $ini_file"
                fi
                info "result-success->$php"
            )
            
            if [ $? != 0 ] ; then
                continue
            fi
        done
    done

    info "all tasks completed"
}


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  get_file_modified_time
#   DESCRIPTION:  get modify time of file
#    PARAMETERS:  $1:file path
#       RETURNS:  time
#-------------------------------------------------------------------------------
get_file_modified_time ()
{
    path="$1"
    valid "[ -f $path ]"
    echo `stat $1 | sed -n "7p" | awk '{print $3}'`
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  restart
#   DESCRIPTION:  restart php-fpm
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
restart()
{
    php_fpm=$1
    if [ -z $php_fpm ] ; then
        php_fpm=php_fpm
    fi
    
    if [ ! -z "`ps -e|grep php-fpm|grep -v grep`" ] ; then
        exec_cmd "killall php-fpm"
    fi
    killall php-fpm > /dev/null 2>&1
    
    exec_cmd "$php_fpm"
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  test
#   DESCRIPTION:  test smart_agent
#    PARAMETERS:  $1:php version;$2:if nginx
#       RETURNS:  
#-------------------------------------------------------------------------------
test ()
{
    test_list=`ls $PHP_SOFTWARE_DIR`

    for version in $test_list; do
        log "test for $version"
        if [ -z "$1" ] ; then
            ( test_nginx $version )
        else
            ( test_apache $version )
        fi
    done
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  test_nginx
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
test_nginx ()
{
    version=$1
    api=`echo $test_api | sed -n 's/port/80/p'`
    log_path="/data/log/phpagent/trace_data.json"
    exec_cmd "/data/software/nginx/sbin/nginx -s reload"
    restart ${PHP_SOFTWARE_DIR}${version}/sbin/php-fpm

    time_pre=`get_file_modified_time $log_path`
    exec_cmd "curl $api >> /dev/null 2>&1"
    sleep 3
    time_end=`get_file_modified_time $log_path`
    log "$time_pre $time_end"

    if [ "$time_pre" == "$time_end" ] ; then
        error "time not changed"
        exit 
    fi

    valid "cat $log_path | jq ."

    valid "[[ `cat $log_path | jq .maps[].mn | grep array | uniq | wc -l` == 0 ]]"

    info "result-sucess:test $version ok"
}	# ----------  end of function test_nginx  ----------


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  test_apache
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
test_apache ()
{
    version=$1
    api=`echo $test_api | sed -n 's/port/8000/p'`
    log_path="/data/log/phpagent/trace_data.json"
    main_php_version=`echo $version | cut -d '.' -f1`
    if [ -z "$IF_FASTCGI" ] ; then
        valid "sed -i \"/php[57]_module/d\" /data/software/apache/conf/httpd.conf"
        valid "sed -i -e '\$aLoadModule php${main_php_version}_module modules/${version}.so' /data/software/apache/conf/httpd.conf"
    fi
    valid "/data/software/apache/bin/apachectl restart"

    time_pre=`get_file_modified_time $log_path`
    exec_cmd "curl $api >> /dev/null 2>&1"
    sleep 3
    time_end=`get_file_modified_time $log_path`

    if [ "$time_pre" == "$time_end" ] ; then
        error "time not changed"
        exit 
    fi

    exec_cmd "cat $log_path | jq ."

    exec_cmd "[[ `cat $log_path | jq .maps[].mn | grep array | uniq | wc -l` == 0 ]]"

    info "result-sucess:test $version ok"
}	# ----------  end of function test_apache  ----------

#命令列表
case $1 in
    #install modules
    "install" | "i")
        install "$2" "$3"
        ;;

    #check which php version and which module will be dealed
    "check" | "c")
        check_version "$2" "$3"
        ;;

    #restart php-fpm
    "restart" | "r")
        restart $2
        ;;

    #test smart_agent
    "test" | "t")
        install
        test $2
        ;;

    *)
        print_info "Usage:   ./$0 (i)nstall [module_name] [php version]"
        print_info "\t ./$0 (c)heck [module_name] [php version] **dump info,not install"
        print_info "\t ./$0 (r)estart [php-fpm path]"
        print_info "\t ./$0 (t)est [php version] **only for smart_agent"

        ;;
esac
