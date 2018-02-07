#!/bin/bash

sanitize() {
	echo $1 | sed -Ee "s@$PWD@~@"
}

find $PWD -type d | grep -vEe "\.git" | while read line
do
	mkdir -p $(sanitize $line)
done

find $PWD -type f | grep -vEe "\.git" | while read line
do
	ln -s $line $(sanitize $line)
done
