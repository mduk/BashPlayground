quotary() {
  declare -a array=${!1}
  for elem in "${array[@]}"
  do echo " '$elem'"
  done
}

gutter=3
y_gutter=2
sidebar_x=30

x=$(tput cols)
y=$(tput lines)

echo "screen: ${x}x${y}"

backtitle="Test Shell Browser"
declare -a environments=( dev2 ppe ppetst )

if [[ ! -z $backtitle ]]
then
  y_margin=3
  x_margin=2
  backtitle="--backtitle '$backtitle'"
else
  y_margin=1
  x_margin=2
fi

env_height=7
env_height=$(($env_height + ${#environments[@]}))

declare env=$(
  eval dialog \
    "$backtitle" \
    --no-items \
    --menu "'SelectEnvironment'" $env_height $sidebar_x $env_height $(quotary environments) \
    3>&1 1>&2 2>&3
)

run_pos_x=$x_margin
run_pos_y=$(($y_margin + $env_height + $y_gutter))
run_height=$(($y - ($y_margin * 2) - $env_height))

out_pos_x=$(($x_margin + $sidebar_x + $gutter))
out_pos_y=$y_margin
out_height=$(($y - $y_margin - $gutter))
out_width=$(($x - ($x_margin * 2) - $sidebar_x - $x_margin))

set -x
eval dialog \
  "$backtitle" \
  --begin $y_margin $x_margin \
    --no-items \
    --menu "'Run Suite'" $run_height $sidebar_x $run_height foo bar baz \
  --and-widget --begin $out_pos_y $out_pos_x \
    --prgbox "'Command Output'" "'OBDENV=$env ./obdtsh suites/regressions/DIR-1482.sh'" $out_height $out_width \
