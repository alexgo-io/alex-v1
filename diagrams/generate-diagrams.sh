#!/bin/sh

# first install cli for yuml (https://github.com/wandernauta/yuml)

class_list='class-diagram'
usecase_list='use-case-back-end use-case-arbitrageur use-case-lender use-case-borrower use-case-lp use-case-fee use-case-yield-farming'

for i in $class_list; do
    yuml -i $i.yuml -t class -s nofunky -f svg -o $i.svg
done

for i in $usecase_list; do
    yuml -i $i.yuml -t usecase -s nofunky -f svg -o $i.svg
done


