err() {
  echo "$@" >&2
}

while [[ $# -gt 0 ]]
do
  case "$1" in
    *:)
      declare    param_name="${1%:}"
      declare -a "param_${1%:}=()"
      declare -n param_var="param_${1%:}"
      declare -n param_rules="param_${1%:}_rules"
      ;;

    '[')
      shift
      declare -i depth=0
      while [[ $# -gt 0 ]] && ( [[ $1 != ']' ]] || [[ $depth -gt 0 ]] )
      do
        case "$1" in
          '[')
            ((depth++))
            param_var+=("$1")
            ;;

          ']')
            ((depth--))
            param_var+=("$1")
            ;;

          *)
            param_var+=("$1")
            ;;
        esac
        shift
      done
      ;;

    *)
      declare pass=true
      if [[ -n $param_rules ]]
      then
        for rule in $param_rules
        do

          # Dereference predefined rules
          if [[ "$rule" == :* ]]
          then
            if [[ -z "${PARAM_RULES[${rule#:}]}" ]]
            then err "advanced-argument-parser: validation rule not found: ${rule#:}"
            fi

            rule="${PARAM_RULES[${rule#:}]}"
          fi

          # Evaluate validation rules
          case "$rule" in

            -?)
              if ! eval [[ "$rule" "$1" ]]
              then pass=false
              fi
              ;;

            //*)
              if ! grep -q -E "$1" <<<"${1#/}"
              then pass=false
              fi
              ;;

            /*)
              if ! grep -q "$1" <<<"${1#/}"
              then pass=false
              fi
              ;;

          esac
        done

        if $pass
        then param_var+=("$1")
        else
          err "VALIDATION FAILURE"
          err "  Parameter: [$param_name]"
          err "      Rules: [$param_rules]"
          err "      Value: [$1]"
          return
        fi

      else
        param_var+=("$1")
      fi
      ;;

  esac
  shift
done

