var_dump() {
  while [[ $# -gt 0 ]]
  do
    declare    name="$1"
    declare -n var="$name"

    echo "\$$name (${var@a})"
    case "${var@a}" in

      *a*|*A*)
        for i in "${!var[@]}"
        do echo " - [$i][${var[$i]}]"
        done
        ;;

      *)
        echo " ${var}"
        ;;

    esac
    shift

    echo
  done
} >&2
