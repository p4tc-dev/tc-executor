#!/bin/bash

if [ "$(cat /debug-mode)" = "true" ]; then
	echo "=== >>> DEBUG KERNEL <<< ==="
	./nipa/contest/remote/vmksft-p.py /tmp/tdc-debug.config
else
	./nipa/contest/remote/vmksft-p.py /tmp/tdc.config
fi

chown -R hostuser:hostuser /storage 
