#!/bin/bash

. cadence2011

rm -rf INCA_libs
rm -rf waves.shm

#irun -f file.vc -sv  -gui & 
irun -f file.vc -sv & 
