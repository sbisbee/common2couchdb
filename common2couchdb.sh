#!/bin/sh
# Copyright 2009 Sam Bisbee
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License.  You may obtain a copy
# of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.

usage()
{
  echo "$0 [-s\"Nov 24, 2009 17:12\"]"
}

#min unix timestamp
minTime=0

while getopts s: flag
do
  case "$flag"
  in
    s)  
      minTime=`date +%s -d"$OPTARG"`
      if test $? -ne 0
      then
        #bad timestamp (or its format)
        usage
        exit 1
      fi
      ;;

    [?])
      usage
      exit 1
      ;;
  esac
done

#Open up shop.
echo -n "{\"docs\": ["

#So we can decide whether to output an array delim or not. Will be unset after
#first loop iteration.
isFirstRun="1"

while read line
do
  #Store our two globbers...
  timestamp=`echo -n $line | sed -e 's/^.*\[\(.*\)\].*$/\1/'`

  unixTime=`echo "$timestamp" | tr [/:] " " | awk '{printf "%s %s, %s %s:%s:%s", $2, $1, $3, $4, $5, $6;}'`
  unixTime=`date +%s -d"$unixTime"`

  if test $unixTime -lt $minTime
  then
    continue
  fi
  unset unixTime

  request=`echo -n $line | sed -e 's/^.*"\(.*\)".*$/\1/'`

  #...and then remove them so that we can...
  line=`echo -n $line | sed -e 's/\[.*\]//' -e 's/".*"//'`

  #...iterate through the rest of the one column values.
  i=0
  for col in $line
  do
    if test $i -eq 0 
    then
      host="$col"
    elif test $i -eq 1
    then
      identifier="$col"
    elif test $i -eq 2
    then
      user="$col"
    elif test $i -eq 3
    then
      httpStatus="$col"
    elif test $i -eq 4
    then
      bytes="$col"
    fi

    i=`expr $i + 1`
  done

  unset i 

  #Throw in our array delim if this isn't our first run.
  if test ! $isFirstRun
  then
    echo -n ","
  fi

  unset isFirstRun

  #Output this entry's document into the array.
  echo -n "{\"host\": \"$host\",\"user\": \"$user\",\"identifier\": \"$identifier\",\"timestamp\": \"$timestamp\",\"request\": \"$request\",\"httpStatus\": \"$httpStatus\",\"bytes\": \"$bytes\"}"
done

#Close up shop.
echo "]}"
