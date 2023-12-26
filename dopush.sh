#!/bin/bash

commitmessage="$1"
if [ x"$commitmessage" == x ]; then
    echo "usage: $(basename $0) <commitmessage>"
    exit 1
fi

sed -i -e 's/^theme:/#theme:/' -e 's/^#remote_theme:/remote_theme:/' _config.yml

git add -A .
git commit -m "$commitmessage"
git push

sed -i -e 's/^#theme:/theme:/' -e 's/^remote_theme:/#remote_theme:/' _config.yml

dest='../zubeax.gitea.io'

rsync -av . $dest --exclude .git --exclude _site --exclude vendor --exclude .jekyll_cache

for i in _site vendor .jekyll_cache
do
    rm -rf $dest/$i
done

pushd . 2>&1 > /dev/null
cd $dest
git add -A .
git commit -m "$commitmessage"
git push
popd . 2>&1 > /dev/null

exit 0

