#!/bin/sh

# first install cli for yuml (https://github.com/wandernauta/yuml)

class_list=''
usecase_list='use-case-back-end use-case-arbitrageur use-case-lender use-case-borrower use-case-lp use-case-fee use-case-yield-farming use-case-borrower-repay'

while getopts ":c:u:" opt; do
  case $opt in
    c) class_list="$OPTARG"
    ;;
    u) usecase_list="$OPTARG"
    ;;
    \?)
    printf "***************************\n"
    printf "* Error: Invalid argument.*\n"
    printf "***************************\n"
    exit 1
    ;;
  esac
done

for i in $class_list; do
    yuml -i $i.yuml -t class -s nofunky -f svg -o $i.svg
done

for i in $usecase_list; do
    yuml -i $i.yuml -t usecase -s nofunky -f png -o $i.png
done


