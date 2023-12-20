#!/bin/bash

repo=$(basename $(realpath $(dirname ${0})))

export PAGES_REPO_NWO=${repo}

bundle exec jekyll serve --host=0.0.0.0 --incremental --watch --force_polling

exit 0


