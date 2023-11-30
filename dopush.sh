#!/bin/bash

commitmessage="$1"
if [ x"$commitmessage" == x ]; then
    echo "usage: $(basename $0) <commitmessage>"
    exit 1
fi

git add -A
git commit -m "$commitmessage"
git push

exit 0

