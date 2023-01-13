#!/bin/bash

NAME=JDETR01_15214
tnspingOutput=$(tnsping ${NAME})
cutString=")))"
firstPart=${tnspingOutput%$cutString*}
tnspingResult=${tnspingOutput: ${#firstPart}-${#tnspingOutput}+4}
echo "${NAME} --> ${tnspingResult}"
