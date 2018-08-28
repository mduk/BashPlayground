myfunction() {
  while [[ $# -gt 0 ]]
  do
    case "$1" in
      *:)
        declare -a "param_${1%:}=()"
        declare -n param_var="param_${1%:}"
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
        param_var+=("$1")
        ;;

    esac
    shift
  done

  echo "foo:"
  for i in $(seq 0 $((${#param_foo[@]}-1)))
  do echo " $i ${param_foo[$i]}"
  done
  echo " @ ${param_foo[@]}"

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
  foo: bar \
  bar: one two three \
  baz: "foo bar" \
  qha: [ one two: three four: five ] \
  nested: [ one two: [ three four ] five: six ] \
  indirected:some_other_var
