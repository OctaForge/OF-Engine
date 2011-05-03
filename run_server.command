#!/bin/sh
cd $(echo $0|sed 's/\/run_server\.command//')
./run_server.sh
exit 0
