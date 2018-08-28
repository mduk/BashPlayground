while [[ $# -gt 0 ]]
do
  case "$1" in

    *:)
      declare param_name="${1%:}"
      shift

      declare param_var="param_${param_name}"

      if [[ ! -z ${!param_var+x} ]]
      then declare "${param_var}=$1"
      else echo "Unexpected Parameter: ${param_name}" >&2
      fi

      shift
      ;;

    *...)
      declare param_name="${1%...}"
      shift

      declare param_var="param_${param_name}"

      set -x
      if [[ ! -z ${!param_var+x} ]]
      then
        echo "\$@ : $@"
        echo ${param_var}=${@}
        declare ${param_var}=${@}
      else echo "Unexpected Parameter: ${param_name}" >&2
      fi
      set +x

      break
      ;;

  esac
done
