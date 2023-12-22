#!/bin/bash

repo=$(basename $(realpath $(dirname ${0})))

export PAGES_REPO_NWO=${repo}

draftsclause=""
[[ x"${1}" == x--drafts    ]] && { draftsclause="--drafts"; }
[[ x"${1}" == x--no-drafts ]] && { draftsclause=""; }

bundle exec jekyll serve --host=192.168.100.136 $draftsclause --incremental --watch --force_polling 

exit 0


