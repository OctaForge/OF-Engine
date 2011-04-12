#!/bin/sh
cd $(echo $0|sed 's/\/intensity_master\.command//')
./intensity_master.sh
exit 0
