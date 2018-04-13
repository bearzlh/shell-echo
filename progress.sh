#!/bin/sh
current_dir=`dirname $0`
. $current_dir/pattern.sh
setPatternDir .

echo -en `pattern ctrll`
#输出进度条===================================================
echo -en `pattern cpos:5:0`
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
    sleep 0.005
    p=#$p
done

#输出文字===================================================
echo -en `pattern cpos:6:0`
echo -e "normal words"

#开启红色字体
echo -en `pattern ffcred`
echo -e "red words"

#开启蓝色背景
echo -en `pattern fbcblue`
echo -e "red words,blue background color"

#开启黑底白字
echo -en `pattern fbcblack ffcgrey`
echo -e "black bg and white words"

#关闭模式
echo -en `pattern off`
echo -e "close the special pattern,following words are normal"

#输出4个时间===================================================
close=`pattern off`
#echo -en "${red}this is a test${close}\n"
#
#echo -e "nothing happened"

#设置默认输出为紫色字体
set_pattern ffcgreen
#绿色字体
green=`pattern ffcgreen`
#光标移动到第一行第一列
cr1c1=`pattern cpos:1:0`
cr2c1=`pattern cpos:2:0`
cr3c1=`pattern cpos:3:0`
cr4c1=`pattern cpos:4:0`
#光标后边的字符
clear_right=`pattern ctrlk`

echo -en "\033[1;0H\033[32m`date +%H:%M:%S`\033[0m\033[K"
echo -en "${cr2c1}${green}`date +%H:%M:%S`${close}$clear_right"
echo_pattern "${cr3c1}<**`date +%H:%M:%S`**>$clear_right"
label_pattern "<cpos:4:0 <ffcgreen `date +%H:%M:%S`><ctrlk "
