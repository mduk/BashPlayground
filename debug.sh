error() {
  echo "ERROR: $1" >&2 ; shift
  while [[ $# -gt 0 ]]
  do
    echo "       $1"
    shift
  done

  echo

  echo "Trace:" >&2
  (
    echo "Frame Function File Line"
    declare -i i=0
    for ((i = 0; i < ${#FUNCNAME[@]}-1; i++))
    do echo "$i ${FUNCNAME[$i]} ${BASH_SOURCE[$i+1]} ${BASH_LINENO[$i]}"
    done
  ) | column -t | sed 's/^/       /'

  if [[ $BASH_SUBSHELL -gt 0 ]]
  then exit
  fi
}

export -f error
