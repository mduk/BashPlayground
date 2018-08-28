#!/bin/bash

# https://en.wikipedia.org/wiki/Block_Element

tput civis
tput sc

for i in `seq 10`
do
  printf "\u2591"
  sleep 0.2
done

#tput el1
tput rc

for i in `seq 10`
do
  printf "\u2592"
  sleep 0.2
done

tput rc

for i in `seq 10`
do
  printf "\u2593"
  sleep 0.2
done

tput rc

for i in `seq 10`
do
  printf "\u2588"
  sleep 0.2
done

echo

tput cnorm
