#!/bin/bash

trap kill_jobs EXIT
set -e

APP=$1
HAS_FAILED=0

kill_jobs()
{
	kill $(jobs -p) 2>/dev/null || true
}

assert()
{
	if "$@"; then
		echo 'ok'
	else
		echo "failed: $APP $@"
		HAS_FAILED=1
	fi
}

$APP -t 1234 -u 1235 sed 's/[aeiou]//g' & sleep 0.1s
X=`echo hello | nc 127.0.0.1 1234`
assert [ "$X" = "hll" ]
X=`echo world | nc -u -w1 127.0.0.1 1235`
assert [ "$X" = "wrld" ]
kill_jobs

$APP -t 1234 -s echo ls & sleep 0.1s
X=`echo | nc 127.0.0.1 1234`
assert [ "x$X" = "x-c ls" ]
kill_jobs


if [ "$HAS_FAILED" = "1" ]; then
	echo "Something went wrong!"
	exit 1
fi
