#!/bin/sh
current_dir=`dirname $0`
. $current_dir/pattern.sh

p=
for ((i=0;i<=100;i++))
do
    if [ $i -lt 20 ];then
        set_pattern ffcred
    elif [ $i -lt 60 ];then
        set_pattern ffcyellow
    else
        set_pattern ffcgreen
    fi
    printf_pattern "\rprogress:[%-100s]%d%%" "$p" "$i"
    sleep 0.01
    p=#$p
done

echo
