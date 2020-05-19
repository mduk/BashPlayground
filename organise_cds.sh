#!/bin/bash

basepath=$(pwd)

cdspath="${basepath}/CDs"
[[ ! -d "${cdspath}" ]] && mkdir "${cdspath}"

musicpath="${basepath}/Music"
[[ ! -d "${musicpath}" ]] && mkdir "${musicpath}"

for flac in $(find ${cdspath} -name *.flac)
do
  cdpath=$(dirname "$flac")

  while read -r tag
  do
    tagname=$(echo $tag | awk -F'=' '{print tolower($1)}')
    tagnamepath="${musicpath}/by-${tagname}"
    [[ ! -d "${tagnamepath}" ]] && mkdir "${tagnamepath}"

    tagvalue=$(echo $tag | awk -F'=' '{print $2}' | sed -e 's#/#-#g')
    tagvaluepath="${tagnamepath}/${tagvalue}"

    case "${tagname}" in

      cddb|album)
        [[ ! -e "${tagvaluepath}" ]] && ln -s "${cdpath}" "${tagvaluepath}"
        ;;

      artist)
        [[ ! -d "${tagvaluepath}" ]] && mkdir "${tagvaluepath}"

        album=$(metaflac --show-tag=album ${flac} | sed -e 's/.*=//')
        albumpath="${tagvaluepath}/${album}"
        [[ ! -d "${albumpath}" ]] && mkdir "${albumpath}"

        tracknumber="$(metaflac --show-tag=tracknumber "${flac}" | sed -e 's/.*=//')"
        title="$(metaflac --show-tag=title "${flac}" | sed -e 's/.*=//')"

        trackpath="${albumpath}/${tracknumber} - ${title}"
        [[ ! -e "${trackpath}" ]] && ln -s "${flac}" "${trackpath}"
        ;;

      *)
        echo "Skipping ${tagname}"
        continue
        ;;

    esac


    echo "[${tagname}:${tagvalue}]"
  done < <(metaflac --export-tags-to=- "${flac}")
done
