################################################################################
# outbox.sh
#
# Copyright (c) 2018 Daniel Kendell <daniel.kendell@gmail.com>
################################################################################

# Config
declare -A OUTBOX_COLOURS_BG=( [ONE]=24 [TWO]=34 [THREE]=44 [FOUR]=54  )
declare -A OUTBOX_COLOURS_FG=( [ONE]=0  [TWO]=0  [THREE]=0  [FOUR]=255 )

if [[ $DEBUG == true ]]
then
  declare OUTBOX_STACK_INDENT='++'
  declare OUTBOX_LINE_PAD='-'
else
  declare OUTBOX_STACK_INDENT='  '
  declare OUTBOX_LINE_PAD=' '
fi

# State
declare    OUTBOX_WINDOW_WIDTH=$(tput cols)
declare -a OUTBOX_STACK=()

################################################################################
# Interface Functions
################################################################################
outbox() {
  declare subcommand="$1"; shift

  declare reset="\033[0m"
  declare eol="\033[K"

  case "$subcommand" in
    begin)
      declare boxtype="$1"; shift
      declare boxtitle="$@"

      OUTBOX_STACK+=( "$boxtype" )

      if [[ ! -z "$boxtitle" ]]
      then
        declare boxtab="${boxtitle}${OUTBOX_STACK_INDENT}"

        declare stack_indentation_width=$((
          ${#OUTBOX_STACK[@]} * 2
        ))

        declare line_space_width=$((
          $OUTBOX_WINDOW_WIDTH - ${#boxtab} - ( $stack_indentation_width * 2 )
        ))

        declare line_space=$(
          for i in $(seq $line_space_width)
          do echo -n "${OUTBOX_LINE_PAD}"
          done
        )

        outbox_print_stack
        echo -ne "\033[48;5;${OUTBOX_COLOURS_BG[$boxtype]}m"
        echo -ne "\033[38;5;${OUTBOX_COLOURS_FG[$boxtype]}m"
        echo -n  "${boxtab}"

        if [[ ${#OUTBOX_STACK[@]} -gt 1 ]]
        then
          declare parent_boxtype="${OUTBOX_STACK[${#OUTBOX_STACK[@]}-2]}"
          echo -ne "\033[48;5;${OUTBOX_COLOURS_BG[$parent_boxtype]}m"
          echo -n  "${line_space}${OUTBOX_STACK_INDENT}"
          outbox_print_stack_reverse true
        fi

        echo -ne "${reset}"
        echo
      fi

      outbox_print_spacer
      ;;

    println)

      while [[ $# -gt 0 ]]
      do
        declare line="$1"
        shift

        declare line_width=$((
          $OUTBOX_WINDOW_WIDTH - ( ${#OUTBOX_STACK[@]} * 4 )
        ))

        if [[ ${#line} -gt $OUTBOX_WINDOW_WIDTH ]]
        then
          declare folded_line=$(echo "$line" | fold -w $(( $line_width - 1 )))
          while read wrapped_line
          do outbox_println "$wrapped_line↩"
          done < <(echo "$folded_line" | head -n -1)
          outbox_println $(echo "$folded_line" | tail -n 1)
        else
          outbox_println "$line"
        fi
      done

      ;;

    spacer)
      outbox_print_spacer
      ;;

    end)
      outbox_print_spacer
      unset 'OUTBOX_STACK[${#OUTBOX_STACK[@]}-1]'
      outbox_print_spacer
      ;;

    *)
      echo "outbox '$1' ???"
      ;;

  esac

}

test_outbox() {
  _test_outbox_stack
  _test_outbox_notitles
  _test_outbox_titles
  _test_outbox_mixedstyles
  _test_outbox_longlines
}

################################################################################
# Private Functions
################################################################################

outbox_println() {
  declare line="$@"

  declare line_space_width=$((
    $OUTBOX_WINDOW_WIDTH - ${#line} - ( ${#OUTBOX_STACK[@]} * 4 )
  ))

  declare line_space=$(
    for i in $(seq $line_space_width)
    do echo -n "${OUTBOX_LINE_PAD}"
    done
  )

  outbox_print_stack
  echo -ne "\033[48;5;${OUTBOX_COLOURS_BG[$boxtype]}m"
  echo -ne "\033[38;5;${OUTBOX_COLOURS_FG[$boxtype]}m"
  echo -n "$line"
  echo -n "$line_space"
  outbox_print_stack_reverse
  echo
}

outbox_print_stack() {
  for boxtype in "${OUTBOX_STACK[@]}"
  do
    echo -ne "\033[48;5;${OUTBOX_COLOURS_BG[$boxtype]}m"
    echo -ne "\033[38;5;${OUTBOX_COLOURS_FG[$boxtype]}m"
    echo -ne "${OUTBOX_STACK_INDENT}"
    echo -ne "${reset}"
  done
}

outbox_print_stack_reverse() {
  declare lessone="${1:-false}"
  declare startoffset=1

  if [[ $lessone == true ]]
  then startoffset=2
  fi

  for (( i = ( ${#OUTBOX_STACK[@]} - $startoffset ); i >= 0; i-- ))
  do
    declare boxtype="${OUTBOX_STACK[i]}"
    echo -ne "\033[48;5;${OUTBOX_COLOURS_BG[$boxtype]}m"
    echo -ne "\033[38;5;${OUTBOX_COLOURS_FG[$boxtype]}m"
    echo -ne "${OUTBOX_STACK_INDENT}"
    echo -ne "${reset}"
  done
}

outbox_print_spacer() {
  declare stack_indentation_width=$((
    ${#OUTBOX_STACK[@]} * 2
  ))

  declare line_width=$((
    $OUTBOX_WINDOW_WIDTH - ( $stack_indentation_width * 2 )
  ))

  declare line_space=$(
    for i in $(seq $line_width)
    do echo -n "${OUTBOX_LINE_PAD}"
    done
  )

  outbox_print_stack
  echo -ne "\033[48;5;${OUTBOX_COLOURS_BG[$boxtype]}m"
  echo -ne "\033[38;5;${OUTBOX_COLOURS_FG[$boxtype]}m"
  echo -ne "${line_space}"
  outbox_print_stack_reverse
  echo -ne "${reset}"
  echo
}


################################################################################
# Tests
################################################################################
_test_outbox_longlines() {
  echo "really long lines"
  echo

  outbox begin ONE
  outbox begin TWO
  outbox begin THREE
  outbox begin FOUR
  outbox println "$(ifconfig)"
  outbox end
  outbox begin FOUR
  (IFS=$'\n'; outbox println $(ifconfig))
  outbox end
  outbox end
  outbox end
  outbox end

  echo
  echo
}

_test_outbox_mixedstyles() {
  echo "Mixed styles"
  echo

  outbox begin ONE 'Title One'
  outbox println "I'm on the first level"
  outbox spacer

    outbox begin TWO 'Title Two'
    outbox println "I'm on the second level"
    outbox spacer

      outbox begin THREE
      outbox println "I'm on the third level"
      outbox end

      outbox begin THREE
      outbox println "I'm on the third level"
      outbox end

    outbox end

  outbox end

  echo
  echo
}

_test_outbox_titles() {
  echo "Boxes with title tabs"
  echo

  outbox begin ONE 'Title One'
  outbox println "I'm on the first level"
  outbox spacer

    outbox begin TWO 'Title Two'
    outbox println "I'm on the second level"
    outbox spacer

      outbox begin THREE 'Title Three'
      outbox println "I'm on the third level"
      outbox end

      outbox begin THREE 'Title Three'
      outbox println "I'm on the third level"
      outbox end

    outbox end

  outbox end

  echo
  echo
}

_test_outbox_notitles() {
  echo "Boxes without title tabs"
  echo

  outbox begin ONE
  outbox println "I'm on the first level with no title"
  outbox spacer

    outbox begin TWO
    outbox println "I'm on the second level and have no title"
    outbox spacer

      outbox begin THREE
      outbox println "I'm on the third level and am followed by a spacer but have no title"
      outbox end

      outbox begin THREE
      outbox println "I'm on the third level and am followed by a spacer but have no title"
      outbox end

    outbox end

  outbox end

  echo
  echo
}

_test_outbox_stack() {
  echo "Stack: [${OUTBOX_STACK[@]}]"
  outbox begin ONE 'One'
  echo "Stack: [${OUTBOX_STACK[@]}]"
  outbox begin TWO 'Two'
  echo "Stack: [${OUTBOX_STACK[@]}]"
  outbox begin THREE 'Three'
  echo "Stack: [${OUTBOX_STACK[@]}]"
  outbox end
  echo "Stack: [${OUTBOX_STACK[@]}]"
  outbox end
  echo "Stack: [${OUTBOX_STACK[@]}]"
  outbox end
  echo "Stack: [${OUTBOX_STACK[@]}]"
}
