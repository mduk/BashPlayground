# roundrobin option1 option2 option3 ... optionN

function roundrobin() {
  declare iter=$1
  shift

  declare use=$(($iter % $# + 1))
  echo ${!use}
}

export -f roundrobin
