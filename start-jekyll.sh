#!/bin/bash

repo=$(basename $(realpath $(dirname ${0})))

export PAGES_REPO_NWO=${repo}

draftsclause="--drafts"
[[ x"${1}" == x--drafts    ]] && { draftsclause="--drafts"; }
[[ x"${1}" == x--no-drafts ]] && { draftsclause=""; }

export JEKYLL_ENV=production

#bundle exec jekyll build --trace
bundle exec jekyll serve --host=0.0.0.0 $draftsclause --trace --incremental --watch --force_polling 

exit 0
