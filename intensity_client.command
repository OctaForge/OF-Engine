#!/bin/sh
cd $(echo $0|sed 's/\/intensity_client\.command//')
./intensity_client.sh
exit 0
