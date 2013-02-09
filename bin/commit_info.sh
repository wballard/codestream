#!/usr/bin/env bash
SHA=$2
EMAIL=`git --git-dir=$1 --no-pager show -s --pretty=format:"%aE" $SHA`
NOTES=`git --git-dir=$1 --no-pager show -s --pretty=format:"%N" $SHA`
DIFF=`git --git-dir=$1 --no-pager diff --unified --no-color $SHA^!`

export EMAIL
export NOTES
export DIFF
