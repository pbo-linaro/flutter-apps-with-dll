#!/usr/bin/env bash

set -euo pipefail

curl --help > /dev/null
jq --version > /dev/null
wget --version > /dev/null

all_packages() {
    curl --compressed --silent  https://pub.dev/api/package-names |
    jq .packages |
    grep '^ ' |
    sed -e 's/\s\+"//' -e 's/".*//'
}

get_package_content()
{
    mkdir -p cache
    package=$1
    local url=$(curl -s https://pub.dartlang.org/api/packages/$package |
          jq -r .latest.archive_url)
    version=$(basename $url)
    cached=cache/${package}_${version}.content
    # check if cache file exists AND is not empty
    if [ ! -f $cached ] || [ ! -s $cached ]; then
        wget -q $url -O - | tar tzf - 2>/dev/null > $cached.part &&
        mv $cached.part $cached
    fi
    cat $cached | sed -e "s/^/$package,/" -e 's#$#'",$url#"
}

list_dll_files()
{
    package=$1
    # search for dll in list of files
    get_package_content $package | grep '\.dll' | grep -v '/flutter_windows.dll'
}

export -f list_dll_files get_package_content

list=all_dll.csv
all_packages | parallel --bar -j64 list_dll_files | tee $list
sort $list > $list.sorted
mv $list.sorted $list
