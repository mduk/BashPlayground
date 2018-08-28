for function in $(cat $1/common.sh | sed -n '/^.*()/s/^\(.*\)().*/\1/p')
do
  declare newname=$(echo $function | tr '-' '_')
  echo $function '->' $newname
  set -x
  for file in $(find "$1" -name '*.sh')
  do sed -i "s/$function/$newname/" $file
  done
done
