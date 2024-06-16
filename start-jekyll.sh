#!/bin/bash

draftsclause="--drafts"
[[ x"${1}" == x--drafts    ]] && { draftsclause="--drafts"; }
[[ x"${1}" == x--no-drafts ]] && { draftsclause=""; }

export JEKYLL_ENV=production
export JEKYLL_GITHUB_TOKEN=$(cat token)
export PAGES_REPO_NWO="https://github.com/zubeax"

#bundle exec jekyll build --trace
bundle exec jekyll serve --host=0.0.0.0 $draftsclause --trace --incremental --watch --force_polling 

exit 0
