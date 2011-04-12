#!/bin/sh
cd $(echo $0|sed 's/\/intensity_server\.command//')
./intensity_server.sh
exit 0
