#!/bin/sh

#引入文件
. ./pattern.sh
#初始化脚本目录
setPatternDir .

echo -e "正常字体"

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
