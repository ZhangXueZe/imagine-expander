#!/bin/zsh
# imagine-expander daemon script
gpu=1
port=8812
if [ $# -eq 2 ]; then
    gpu=$1
    port=$2
fi
source /home/ubuntu/.zshrc
echo stdbuf -o 0 th web.lua -gpu $gpu -port $port >> ./imagine-expander_${port}.log 2>&1
stdbuf -o 0 th web.lua -gpu $gpu -port $port >> ./imagine-expander_${port}.log 2>&1
