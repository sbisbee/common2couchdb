#!/bin/sh
# common2couchdb version 0.1.0
# by Sam Bisbee <sbisbee@computervip.com> on 2009-11-23 at 1700 -0500
#
# 
#
# Takes a common log formatted web server log (ex., Apache access logs) over
# stdin and stores each entry in a JSON array. You can easily add extra fields
# to the objects for your use (ex., adding a meaningful _id for storing in
# CouchDB).
#
# Each log entry gets put into this format (note: all values are strings):
# {
#   "host": "",       //hostname or IP
#   "user": "",       //the user doing the requesting
#   "identifier": "", //the user's identifier
#   "timestamp": "",  //format: dd/MMM/yyyy/:hh/:mm/:ss/ +-hhmm
#   "request": "",    //the HTTP request line
#   "httpStatus": "", //valid HTTP status code
#   "bytes": ""       //size of response in bytes
# }
#
# Note, most web servers will output a "-" if a piece of information is missing
# (ex., user) or inappropriate (ex., bytes on a HTTP 304). We don't check to
# see if a value is filled, we just pass through what's in the log. 
#
# Output is on stdout, so feel free to pipe to a file, ncurses, etc.
#
# Wish List:
# * Allow user to specify a min, or start, date to avoid duplication and
#   generally unhappy work.

#Open up shop.
echo -n "{\"docs\": ["

#So we can decide whether to output an array delim or not. Will be unset after
#first loop iteration.
isFirstRun="1"

while read line
do
  #Store our two globbers...
  timestamp=`echo -n $line | sed -e 's/^.*\[\(.*\)\].*$/\1/'`
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
