###功能
```
1.输出颜色
2.输出格式
```

###配置文件内容
```
$ cat pattern.txt
off 0m        #关闭所有属性 
fhl 1m        #设置高亮度 
ful 4m        #下划线 
fshine 5m     #闪烁 
freverse 7m   #反显 
fblank 8m     #消隐 
ffcblack 30m  #文字黑色
ffcred 31m    #文字红色
ffcgreen 32m  #文字绿色
ffcyellow 33m #文字黄色
ffcblue 34m   #文字蓝色
ffcpurple 35m #文字紫色
ffccyan 36m   #文字青色
ffcgrey 37m   #文字灰色
fbcblack 40m  #背景黑色
fbcred 41m    #背景红色
fbcgreen 42m  #背景绿色
fbcyellow 43m #背景黄色
fbcblue 44m   #背景蓝色
fbcpurple 45m #背景紫色
fbccyan 46m   #背景青色
fbcgrey 47m   #背景灰色
cun [X]A      #光标上移n行 
cdn [X]B      #光标下移n行 
crn [X]C      #光标右移n行 
cln [X]D      #光标左移n行 
cpos [X];[Y]H #设置光标位置 
ctrll 2J      #清屏 
ctrlk K       #清除从光标到行尾的内容 
csave s       #保存光标位置 
crestore u    #恢复光标位置 
chide ?25l    #隐藏光标 
cshow ?25h    #显示光标
```
###说明
```
* f->font
* c->cursor
* hl->hightlight
* fc->foreground color
* bc->background color
* u->up
* d->down
* l->left
* r->right
* pos->position

```
###进度条示例
```
#!/bin/sh

#引入文件
. ./pattern.sh
#初始化脚本目录
setPatternDir .

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
```
###颜色示例
```
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
echo -e "red words,blue bg color"

#开启黑底白字
echo -en `pattern fbcblack ffcgrey`
echo -e "black bg and white words"

#关闭模式
echo -en `pattern off`
echo -e "close the special pattern,following words are normal”
```

$ ./test.sh 

```
正常字体
red words
red words,blue bg color
black bg and white words
close the special pattern,following words are normal
```