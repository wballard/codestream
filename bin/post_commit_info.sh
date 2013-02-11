#!/usr/bin/env bash

REPO=$2
SHA=$3
EMAIL=`git --git-dir=$1 --no-pager show -s --pretty=format:"%aE" $SHA`
DATE=`git --git-dir=$1 --no-pager show -s --pretty=format:"%aD" $SHA`
NOTES=`git --git-dir=$1 --no-pager show -s --pretty=format:"%B" $SHA`
DIFF=`git --git-dir=$1 --no-pager diff --unified --no-color $SHA^!`

export EMAIL
export NOTES
export DATE
export DIFF
export REPO
export SHA

json render templates/commit.mustache | hipchat rooms message "Codestreams" $EMAIL
echo $SHA
