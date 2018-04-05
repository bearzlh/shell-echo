#!/bin/sh
current_dir=`dirname $0`
. $current_dir/pattern.sh

p=
for ((i=0;i<=100;i+=2))
do
    if [ $i -lt 10 ];then
        set_pattern ffcred
    elif [ $i -lt 30 ];then
        set_pattern ffcyellow
    else
        set_pattern ffcgreen
    fi
    printf_pattern "\rprogress:[%-50s]%d%%" "$p" "$i"
    sleep 0.01
    p=#$p
done
