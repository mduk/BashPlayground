array_to_assoc() {
  if [[ $# -lt 2 ]]
  then
    echo 'Usage: array_to_assoc name_of_input_array name_of_output_assoc_array' >&2
    return 1
  fi

  declare -n input_array="$1"
  declare -n output_array="$2"

  if [[ ${input_array@a} != *a* ]]
  then
    echo 'array_to_assoc: error: input array is not an array (has no -a attribute)' >&2
    return 2
  fi

  if [[ ${output_array@a} != *A* ]]
  then
    echo 'array_to_assoc: error: output array is not an associative array (has no -A attribute)' >&2
    echo '           suggestion: Did you declare the array without setting an initial empty value?' >&2
    echo '                       Eg: declare -A MY_ASSOC_ARRAY vs declare -A MY_ASSOC_ARRAY=()' >&2
    return 3
  fi

  set -- "${input_array[@]}"

  while [[ $# -gt 0 ]]
  do
    declare key="${1%:}"; shift
    declare val="$1"; shift

    output_array["$key"]="$val"
  done
}

assoc_to_array() {
  if [[ $# -lt 2 ]]
  then
    echo 'Usage: assoc_to_array name_of_input_assoc_array name_of_output_array' >&2
    return 1
  fi

  declare -n input_array="$1"
  declare -n output_array="$2"


  for k in "${!input_array[@]}"
  do
    output_array+=("${k}:")
    output_array+=("${input_array[$k]}")
  done
}
