#!/bin/sh
cd $(echo $0|sed 's/\/run_client\.command//')
./run_client.sh
exit 0
