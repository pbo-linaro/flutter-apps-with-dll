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

list_dll_files()
{
    package=$1
    # get latest package published
    content=$(curl -s https://pub.dartlang.org/api/packages/$package |
              jq -r .latest.archive_url)

    # search for dll in list of files
    for dll in $(wget -q $content -O - | tar tzf - 2>/dev/null | grep 'dll$'); do
        echo $package:$dll
    done
}

export -f list_dll_files

all_packages | parallel --bar -j200 list_dll_files
