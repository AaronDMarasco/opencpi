#!/bin/bash 
rt=$( ../include/uut.sh $1 );
rc=$?

if [[ $rc != 0 ]]; then
    echo $rt;
    exit $rc;
fi
./unitTest --utname=sym_fir_complex --compp="<property name='deviation' value='100'/>" --utp="<property name='taps' value='-2,11,22,27,25,15,0,-14,-25,-29,-25,-13,2,19,31,35,29,15,-3,-22,-35,-40,-34,-18,2,22,37,41,34,16,-6,-28,-43,-46,-35,-14,12,38,54,57,43,17,-14,-44,-63,-66,-51,-22,13,46,66,68,50,16,-23,-60,-80,-78,-53,-9,40,84,109,105,73,19,-43,-98,-130,-127,-91,-28,44,106,139,132,84,5,-82,-154,-186,-166,-92,20,144,245,292,267,168,14,-157,-301,-377,-357,-239,-47,168,346,426,370,174,-123,-447,-699,-781,-623,-206,417,1128,1752,2094,1983,1317,106,-1510,-3263,-4777,-5633,-5435,-3884,-851,3582,9113,15238,21318,26666,30645,32767'/>" --real=false --model=$1

