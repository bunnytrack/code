# echo Warning: getres will crash on images without exp
# jnn test $1 -wskip 2
jnn scan $1 -wskip 2 -mr 2
mkdir results
blob ../images/$1.bmp textseg.bmp results/$1blob.bmp
mv windowmeas.bmp results/$1.bmp
mv textseg.bmp results/$1top.bmp
