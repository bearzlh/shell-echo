#!/bin/sh
#批量编译安装php。只编译php-fpm,apache的libphp,debug选项，分是否支持zts两个版本

LIB='libjpeg-turbo-devel libmcrypt-devel libpng-devel libmcrypt-devel openssl-devel'

#php源码目录，名称格式：php-5.3.29
PHP_SRC_DIR="/data/src/php/"

#待安装的php目录列表
TO_INSALL_LIST=`ls $PHP_SRC_DIR | grep "tar.gz" | grep "$1"`

#日志文件
LOG=/data/log/php_install

#安装到哪个目录
TARGET_DIR='/data/software/php/'

#so文件放置到的目录
SO_DIR='/data/so_dir/'

#apache的模块目录
APACHE_DIR='/data/software/apache/'

#启用debug选项,如果为空则不开启
DEFAULT="--with-pdo-mysql --with-mysqli --with-curl --with-mcrypt --with-openssl --enable-mbstring --with-gd --enable-zip --enable-fpm --with-apxs2=${APACHE_DIR}bin/apxs"

#空格替换符号
SPLIT='||'

#zts选项
zts_flag="--enable-maintainer-zts ${SPLIT}"

#apax_flag="--with-apxs2=${APACHE_DIR}bin/apxs"

#加载日志文件
. ./log.sh
checkEnv()
{
   for lib in $LIB
   do
       count=`rpm -ql $lib|wc -l`
       if [ $count -eq 1 ];then
           log "$lib required,installing"
           yum -y install $lib>>$LOG 2>&1
           if [ $? != 0 ];then
               error "$lib install error"
           else
               info "$lib installed"
           fi
       fi
   done
}

checkEnv
#备份so文件
backUpSo()
{
    if [ ! -d $SO_DIR ];then
        mkdir -p $SO_DIR
    fi
    module_dir=${APACHE_DIR}modules
    php_so=`ls $module_dir | grep php`
    if [ -f "$module_dir/$php_so" ];then
        mv $module_dir/$php_so $SO_DIR${1}.so
    fi
}

#编译
runMake()
{
    #zts选项
    for zts in $zts_flag
    do
        flags=`echo "$DEFAULT $zts" | sed "s/"$SPLIT"/ /g"  | sed 's/ \+/ /g'`

        suffix=$version
        if [[ ! -z `echo "$flags" | grep "zts"` ]];then
            #flags="$flags $apax_flag"
            suffix=${suffix}_zts
         else
            suffix=${suffix}_nts
            if [ `echo $version | cut -d "." -f1,2` == "5.3" ];then
                $flags="$flags $fpm_flag"
            fi
        
        fi

        log "make distclean"
        make distclean >> $LOG 2>&1
        log "./configure --prefix=${TARGET_DIR}${suffix} $flags"
        ./configure --prefix=${TARGET_DIR}${suffix} $flags >> $LOG 2>&1
        if [ $? != 0 ];then
            error "configure error,continue,$verion\n"
            continue;
        fi
        log "sed -i 's/-g /-g3 -gdwarf-2 /g' Makefile"
        sed -i 's/-g /-ggdb3 /g' Makefile
        log "make"
        if [ $? != 0 ];then
            error "make error,continue,$verion\n"
            continue;
        fi
        make >> $LOG 2>&1
        log "make install"
        #如果已经安装，则删除
        if [ -d "${TARGET_DIR}${suffix}" ];then
            rm -rf ${TARGET_DIR}${suffix}
        fi
        #如果已经存在phpso文件，则删除
        if [ ! -z "`ls ${APACHE_DIR}modules | grep php`" ];then
            rm -rf ${APACHE_DIR}modules/libphp*.so
        fi
        make install >> $LOG 2>&1
        if [[ "$flags" == *apxs*  ]];then
            log "backUpSo $suffix"
            backUpSo $suffix
        fi
        log "php.ini-development ${TARGET_DIR}${suffix}/lib/php.ini"
        cp php.ini-development ${TARGET_DIR}${suffix}/lib/php.ini
        info "successful $suffix with $flags"
    done
}

#遍历php版本并执行安装
for php in $TO_INSALL_LIST
do
    cd $PHP_SRC_DIR
    dirname=${php%.tar*}
    if [ -d "$dirname" ];then
        rm -rf $dirname
    fi
    tar zxf $php
    version=`echo $dirname|cut -d '-' -f2`
    cd $PHP_SRC_DIR$dirname
    runMake "$version"
done
