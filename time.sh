#!/bin/sh
current_dir=`dirname $0`
. $current_dir/pattern.sh
while [ 1 ]
do
        set_pattern ffcred
        echo_pattern "\r"`date +%H:%M:%S`
        sleep 1
done
