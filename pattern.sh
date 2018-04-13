#!/bin/sh
background_default=grey
foreground_default=black
prefix='\033['
start_pattern=
end_pattern=
current_dir=`dirname $0`

SPLIT='||'

error()
{
    echo -e "\033[31m$1\033[0m"
    exit
}

setPatternDir()
{
   current_dir=`dirname $1`/`basename $1`/
}

getParamsNum()
{
    n=0
    n=$[n + `echo $1 | sed -n '/X/p'|wc -l`]
    n=$[n + `echo $1 | sed -n '/Y/p'|wc -l`]
    echo $n
}

get_matched_pattern()
{
    pattern_list=`sed -n 's/ \+#.*$/\n/p' $current_dir/pattern.txt`
    echo `echo "$pattern_list" | sed -n "/^$1/p" | sed -n "1p"`
}

pattern()
{
    string=
    for param in $@
    do
        param=`echo $param | sed 's/:/ /g;p' | sed -n '$p'`
        params_receive_num=`echo $param | wc -w`
        if [ $params_receive_num -eq 3 ];then
            p1=${param%% *}
            param=${param#* }
            p2=${param%% *}
            p3=${param##* }
        elif [ $params_receive_num -eq 2 ];then
            p1=${param%% *}
            p2=${param##* }
        else
            p1=$param
        fi
        match=`get_matched_pattern "$p1"`
        if [ ! -z "$match" ];then
            params_num=$[`getParamsNum "$match"` + 1]

            if [ $params_receive_num -ne $params_num ];then
                error "${FUNCNAME[0]} ==> should offer $params_num params,$params_receive_num received"
            fi
            code=`echo $match | sed -n 's/.*\ //p'`
            if [ "$params_receive_num" -eq 2 ];then
                code=`echo $code | sed -n "s/\[X\]/$p2/p"`
            elif [ "$params_receive_num" -eq 3 ];then
                code=`echo $code | sed -n "s/\[X\]/$p2/p" | sed -n "s/\[Y\]/$p3/p"`
            fi

            string=$string"$prefix$code"
        fi
    done
    echo $string
}

#设置输入模式
set_pattern()
{
    start_pattern="`pattern $@`"
    end_pattern="`pattern off`"
}

#查看当前输入模式
get_pattern()
{
    echo "$start_pattern" 
}

#重置输入模式
reset_pattern()
{
    start_pattern=
    end_pattern=
}

escape_charactor()
{
    escape='\[]{}.*?'
    count=${#escape}
    r=$1
    #转义次数
    if [ -z $2 ];then
        level=1
    else
        level=$2
    fi

    for ((c = 0; c < $level; c++))
    do
        for ((i = 0; i < $count; i++))
        do
            v1="${escape:i:1}"
            vl='/\'$v1'/\\\'$v1'/'
            if [ ! -z `echo $r | grep -F "$v1"` ];then
                r=`echo $r | sed -n "s${vl}g;p"`
            fi
        done
    done

    echo $r
}

check_pattern()
{
    string=$1
    start_pattern_match=`echo $1 | sed -n "/<\*\*/p"`
    end_pattern_match=`echo $1 | sed -n "/\*\*>/p"`
    start_pattern_escape=`escape_charactor $start_pattern`
    end_pattern_escape=`escape_charactor $end_pattern`

    if [ -z $start_pattern_match -a -z $end_pattern_match ];then
        string=$start_pattern$1$end_pattern
    else
        if [ ! -z $start_pattern_match ];then
            string=`echo $string | sed -n "s/<\*\*/$start_pattern_escape/g;p"`
        fi
        if [ ! -z $end_pattern_match ];then
            string=`echo $string | sed -n "s/\*\*>/$end_pattern_escape/g;p"`
        fi
    fi
    echo $string
}


#echo解析
echo_pattern()
{
    string=`check_pattern $@`
    echo -en $string
}

#printf解析
printf_pattern()
{
    p1=`check_pattern $1`
    r=`escape_charactor $1`
    pl=`echo $@ | sed -n "s/$r//g;p"`
    printf $start_pattern$p1$end_pattern $pl
}

#标签式解析
#执行while循环，循环条件，存在<
#1.获取<后的单词，如果匹配模式，则替换，否则将<替换；获取<之前的>并替换
#    1.1.查看之后是>还是<
#    如果是>且1为匹配模式则将第一个替换为off模式；
#2.循环结束将<与>替换回去
label_pattern()
{
    string="$*"
    #<替换符
    split_lt='||'
    #>替换符
    split_gt='=='
    #查找<
    while [[ ! -z `echo $string | grep "<"` ]]
    do
        #<左侧文本
        pleft_text=${string%%<*}

        #如果左侧文本含有>，则替换
        if [[ ! -z `echo $pleft_text | grep ">"` ]];then
            pleft_text=`echo $pleft_text | sed -n "s/>/$split_gt/p"`
        fi
        #右侧内容
        pright=${string#*<}

        #如果左侧内容含有空格
        if [[ ! -z `echo "$pright" | grep " "` ]];then
            #截取空格左侧
            pflag=${pright%% *}
            #查看是否匹配模式
            match=`pattern "$pflag"`

            #如果匹配模式
            if [[ ! -z $match ]];then
                #截取空格右侧内容
                pright=${pright#* }

                #如果右侧内容中>比<出现早，则将其置为模式关闭
                if [[ "${pright%%>*}" < "${pright%%<*}" ]];then
                    close=`pattern off`
                    pright="${pright%%>*}$close${pright#*>}"
                fi

                string=$pleft_text$match$pright
            else
                string=$pleft_text$split_lt$pright
            fi
        else
            string=$pleft_text$split_lt$pright
        fi
    done

    #将<还原
    if [ ! -z "`echo $string | grep $split_lt`" ];then
        string=`echo $string | sed -n "s/$split_lt/</p"`
    fi
    
    #将>还原
    if [ ! -z "`echo $string | grep $split_gt`" ];then
        string=`echo $string | sed -n "s/$split_gt/>/p"`
    fi

    #输出结果
    echo -en "$string"
}
