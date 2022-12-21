#!/bin/bash
NL='
'
LINE_START=4
sed -i "${LINE_START}i XXX" ./bla
# sed -i "$LINE_START,$LINE_END d" "./bla"
# for ((i=1; i<=(LINE_END - LINE_START + 1); i++))
# do
#     sed -i "$((LINE_START - 1))a $NL" "./bla"
# done

