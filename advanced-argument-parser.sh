exec 5>/tmp/execution.log
BASH_XTRACEFD=5

set -x

stderr() {
  echo "$@" >&2
}

myfunction() {
  declare param_foo=""
  declare param_foo_rules="-n -f"

  declare param_enum=""
  declare param_enum_rules="//(foo|bar)"


  while [[ $# -gt 0 ]]
  do
    case "$1" in
      *:)
        declare    param_name="${1%:}"
        declare -a "param_${1%:}=()"
        declare -n param_var="param_${1%:}"
        declare -n param_rules="param_${1%:}_rules"
        ;;

      *:*)
        declare -n "param_${1%:*}=${1#*:}"
        ;;

      '[')
        shift
        declare -i depth=0
        while [[ $1 != ']' ]] || [[ $depth -gt 0 ]]
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
            case "$rule" in
              -?)
                if ! eval [[ "$rule" "$1" ]]
                then pass=false
                fi
                ;;

              //*)
                declare values="${1#/}"
                if ! grep -q -E ${grep_extended} "$1" <<<"${1#/}"
                then pass=false
                fi
                ;;

              /*)
                declare values="${1#/}"
                if ! grep -q ${grep_extended} "$1" <<<"${1#/}"
                then pass=false
                fi
                ;;
            esac
          done

          if $pass
          then param_var+=("$1")
          else
            stderr "VALIDATION FAILURE"
            stderr "  Parameter: [$param_name]"
            stderr "      Rules: [$param_rules]"
            stderr "      Value: [$1]"
            return
          fi

        else
          param_var+=("$1")
        fi
        ;;

    esac
    shift
  done

  echo "foo:"
  for i in $(seq 0 $((${#param_foo[@]}-1)))
  do echo " $i ${param_foo[$i]}"
  done
  echo " @ ${param_foo[@]}"

  echo "enum:"
  for i in $(seq 0 $((${#param_enum[@]}-1)))
  do echo " $i ${param_enum[$i]}"
  done
  echo " @ ${param_enum[@]}"

  echo "bar:"
  for i in $(seq 0 $((${#param_bar[@]}-1)))
  do echo " $i ${param_bar[$i]}"
  done
  echo " @ ${param_bar[@]}"

  echo "baz:"
  for i in $(seq 0 $((${#param_baz[@]}-1)))
  do echo " $i ${param_baz[$i]}"
  done
  echo " @ ${param_baz[@]}"

  echo "qha:"
  for i in $(seq 0 $((${#param_qha[@]}-1)))
  do echo " $i ${param_qha[$i]}"
  done
  echo " @ ${param_qha[@]}"

  echo "nested:"
  for i in $(seq 0 $((${#param_nested[@]}-1)))
  do echo " $i ${param_nested[$i]}"
  done
  echo " @ ${param_nested[@]}"

  echo "indirected:"
  for i in $(seq 0 $((${#param_indirected[@]}-1)))
  do echo " $i ${param_indirected[$i]}"
  done
  echo " @ ${param_indirected[@]}"

}

declare -a some_other_var=(foo bar baz)

myfunction \
  foo: /etc/hosts \
  enum: foo \
  bar: one two three \
  baz: "foo bar" \
  qha: [ one two: three four: five ] \
  nested: [ one two: [ three four ] five: six ] \
  indirected:some_other_var
