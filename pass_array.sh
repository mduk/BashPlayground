declare -A MY_ARRAY=( [one]=foo [two]="foo bar" [three]=bar )
declare -p MY_ARRAY

function my_function() {

  # The name of the array, or rather, the name of all of the elements of the array
  declare array_name="${1}[@]"
  echo "Using array: $array_name"

  # This line re-constructs the array
  declare -A use_array=("${!array_name}")
  echo "Array contains: ${use_array[@]}"

  # Now the array works as expected
  for elem in "${!use_array[@]}"
  do
    echo "before -> $elem"
  done
  echo

  use_array+=(baz)

  for elem in "${use_array[@]}"
  do
    echo "after -> $elem"
  done
  echo
}

my_function MY_ARRAY

for elem in "${MY_ARRAY[@]}"
do
  echo "outside -> $elem"
done
