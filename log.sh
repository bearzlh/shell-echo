#!/bin/sh
#加载输出颜色脚本
CURRENT_DIR="$(dirname $(readlink -f ${BASH_SOURCE}))/"
source  ${CURRENT_DIR}/pattern.sh

if [ -z $LOG ];then
    LOG=/tmp/log
fi

#当前时间格式化输出
time_format()
{
    echo `date +"%Y-%m-%d %H:%M:%S"`
}

#输出debug信息
log()
{
    blue=`pattern ffcblue`
    off=`pattern off`
    echo -e "`time_format`==>${blue}$1${off}"
    echo "`date`==>$1">>$LOG
}

#输出结束信息
info()
{
    green=`pattern ffcgreen`
    off=`pattern off`
    echo -e "`time_format`==>${green}$1${off}"
    echo "`date`==>$1">>$LOG
}

#输出结束信息
error()
{
    red=`pattern ffcred`
    off=`pattern off`
    echo -e "`time_format`==>${red}$1${off}"
    echo "`date`==>$1">>$LOG
}
