#!/bin/sh
background_default=grey
foreground_default=black
prefix='\033['
start_pattern=
end_pattern=

current_dir=`dirname $0`
pattern_list=`sed -n 's/ \+#.*//p' $current_dir/pattern.txt`

error()
{
    echo -e "\033[31m$1\033[0m"
    exit
}

getParamsNum()
{
    n=0
    n=$[n + `echo $1 | sed -n '/X/p'|wc -l`]
    n=$[n + `echo $1 | sed -n '/Y/p'|wc -l`]
    echo $n
}

pattern()
{
    match=`echo "$pattern_list" | sed -n "/^$1/p"`
    match_words=`echo -n "$match" | wc -w`
    match_num=$[$match_words / 2]
    if [ $match_num -gt 1 ];then
        error "${FUNCNAME[0]} $* ==> should match one;matched:\n`echo \"$match\" | sed -n 's/ .*//p'`"
    elif [ $match_num -eq 0 ];then
        error "${FUNCNAME[0]} $* ==> params error,no matched"
    fi
    paramsNum=$[`getParamsNum "$match"` + 1]
    if [ $# -ne $paramsNum ];then
        error "${FUNCNAME[0]} ==> should offer $paramsNum params,$# received"
    fi
    code=`echo $match | sed -n 's/.*\ //p'`
    if [ $paramsNum -eq 2 ];then
        code=`echo $code | sed -n "s/\[X\]/$2/p"`
    elif [ $paramsNum -eq 3 ];then
        code=`echo $code | sed -n "s/\[X\]/$2/p" | sed -n "s/\[Y\]/$3/p"`
    fi

    echo "$prefix$code"
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

#输出
echo_pattern()
{
    echo -en $start_pattern$@$end_pattern
}


escape_charactor()
{
    escape='\[]{}.*?'
    r=$1
    count=${#escape}
    for ((i = 0; i < $count; i++))
    do
        v1=${escape:i:1}
        vl='/\'$v1'/\\\'$v1'/'
        if [ ! -z `echo $r | grep -F "$v1"` ];then
            r=`echo $r | sed -n "s${vl}g;p"`
        fi
    done
    echo $r
}

printf_pattern()
{
    p1=$1
    r=`escape_charactor $p1`
    pl=`echo $@ | sed -n "s/$r//g;p"`
    printf $start_pattern$p1$end_pattern $pl
}
