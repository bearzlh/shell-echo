#!/bin/sh
current_dir=`dirname $0`
. $current_dir/pattern.sh

red=`pattern ffcred`
close=`pattern off`
#echo -en "${red}this is a test${close}\n"
#
#echo -e "nothing happened"

#设置默认输出为紫色字体
set_pattern ffcpurple
#绿色字体
green=`pattern ffcgreen`
#光标上移一行
up1=`pattern cun:1`
#光标下移一行
down1=`pattern cdn:1`
#光标移动到第一行第一列
cr1c1=`pattern cpos:1:0`
cr2c1=`pattern cpos:2:0`
cr3c1=`pattern cpos:3:0`
cr4c1=`pattern cpos:4:0`
#清除多余字符
clear_right=`pattern ctrlk`

#隐藏光标
#echo -en `pattern chide`
while [ 1 ]
do
    echo -en "${cr1c1}1小时后时间为:${green}`date -d '+1 hour' +%H:%M:%S`${close}$clear_right"
    echo_pattern "\r${cr2c1}当前时间为:<**`date +%H:%M:%S`**>$clear_right"
    echo -en "\r${cr3c1}2小时后时间:`date -d '+2 hour' +%H:%M:%S`$clear_right"
    label_pattern "\r${cr4c1}3小时后时间:<ffccyan `date -d '+3 hour' +%H:%M:%S`>$clear_right"
    sleep 1
done
