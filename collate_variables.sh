collate_variables() {
  declare arg_prefix=''
  declare arg_name_matches=''
  declare arg_value_matches=''
  declare arg_output='keys-and-values'
  source ./src/args.sh

  declare variables=$(set -o posix; set)

  if [[ ! -z $arg_prefix ]]
  then variables=$(echo "$variables" | sed -n "/^$arg_prefix.*=.*/p")
  fi

  if [[ ! -z $arg_name_matches ]]
  then variables=$(echo "$variables" | sed -n "/.*$arg_name_matches.*=.*/p")
  fi

  if [[ ! -z $arg_value_matches ]]
  then variables=$(echo "$variables" | sed -n "/.*=\*$arg_value_matches.*/p")
  fi

  case "$arg_output" in
           prefixes) echo "$variables" | sed 's/\([^_]*\)_.*/\1/' ;;
               keys) echo "$variables" | sed 's/\(.*\)=.*/\1/'    ;;
             values) echo "$variables" | sed 's/.*=\(.*\)/\1/'    ;;
    keys-and-values) echo "$variables"                            ;;
                  *) error "Unknown output value: $arg_output"    ;;
  esac
}
