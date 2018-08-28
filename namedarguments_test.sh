test_namedparams() {
  set foo: bar
  declare param_foo=''
  source ./namedarguments.sh

  if [[ $param_foo == bar ]]
  then echo '1 PASS'
  else echo '1 FAIL'
  fi
}

test_namedtail() {
  set foo... bar baz
  declare param_foo=''
  source ./namedarguments.sh

  if [[ $param_foo == 'bar baz' ]]
  then echo '2 PASS'
  else echo '2 FAIL' $param_foo
  fi
}

test_both() {
  set foo: bar baz: one two three
  declare param_foo=''
  declare param_baz=''

  if [[ $param_foo == bar ]]
  then echo '3a PASS'
  else echo '3a FAIL'
  fi

  if [[ $param_baz == 'one two three' ]]
  then echo '3b PASS'
  else echo '3b FAIL'
  fi
}

test_namedparams
test_namedtail
test_both
