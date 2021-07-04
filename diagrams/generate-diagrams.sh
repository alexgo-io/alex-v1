#!/bin/sh

# first install cli for yuml (https://github.com/wandernauta/yuml)
yuml -i class-diagram.yuml -t class -s nofunky -f svg -o class-diagram.svg
yuml -i use-case-back-end.yuml -t usecase -s nofunky -f svg -o use-case-back-end.svg


