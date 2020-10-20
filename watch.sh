#!/bin/bash

while true; do
  clear
  whazzup=`docker ps | grep mms-user | wc -l`
  if [[ "1" == "$whazzup" ]]; then
    container=`docker ps | grep mms-user | awk '{print $1;}'`
    echo "mms-user is running with container id $container"
    count=`docker exec -it "$container" ls -al /shared_dir | wc -l`
    if [[ "3" == "$count" ]]; then
      echo "(no files)" 
    else
      files=`docker exec -it "$container" ls -al /shared_dir`
      echo "Shared volume (/shared_dir) contents inside this container:"
      echo "$files"
      contents=`docker exec -it "$container" cat /shared_dir/myobject0`
      echo "$contents"
      exit 0
    fi
  fi
  sleep 2
done

