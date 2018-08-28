#!/bin/bash

write() {
  echo $@ >> $mdfile
}

if [[ $# -ne 1 ]]
then
  echo "This tool requires an Atlassian Session Cookie in order to function."
  echo "Log in to Open Banking Atlassian through your browser, then use the"
  echo "Developer Tools to get the Cookie: header value and supply it as the"
  echo "argument to this script."
  echo
  echo "Eg: ./sync-regression-tickets '<pasted cookie>'"
  echo "                            # ^ Use of single quotes is advised"
  exit
fi

echo

declare suitedir='./suites/regressions'

for path in $(find $suitedir -name '*.sh')
do
  declare dir=$(dirname $path)
  declare file=$(basename $path)
  declare ticket=${file%%.sh}
  declare url="https://openbanking.atlassian.net/si/jira.issueviews:issue-xml/${ticket}/${ticket}.xml"
  declare xmlfile="${dir}/${ticket}.xml"
  declare mdfile="${dir}/${ticket}.md"

  echo -n "Downloading Ticket $ticket... "
  if http $url > $xmlfile "Cookie: $1"
  then
    echo "OK"

    declare title=$(cat $xmlfile | hxselect -c 'item title' | recode html..ascii)
    declare description=$(cat $xmlfile | hxselect -c 'item description' | recode html..ascii)
    declare updated=$(cat $xmlfile | hxselect -c 'item updated' | recode html..ascii)

    echo > $mdfile
    write "# Regression: $title"
    write "## Description"
    write $description
  else
    echo "ERROR"
    continue
  fi
done
