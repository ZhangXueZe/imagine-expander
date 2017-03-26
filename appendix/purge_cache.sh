#!/bin/zsh
# cron script for purge cache
source /home/ubuntu/.zshrc
cd /home/ubuntu/imagine-expander
th appendix/purge_cache.lua
