#!/bin/sh

min_col=13
max_col=291
if [ "$1" != "" ]; then
    max_col="$1"
fi
c=`expr ${min_col} + 1`
raion_p1=`cat ../input/test.csv ../input/train.csv | cut -d, -f${min_col} | sort -u | wc -l`
(
echo "col,excess"
while [ $c -lt $max_col ]; do
    name=`head -1 ../input/test.csv | cut -d, -f$c`
    unique_count=`cat ../input/test.csv ../input/train.csv | cut -d, -f${min_col},$c | sort -u | wc -l`
    echo $name,`expr $unique_count - $raion_p1`
    c=`expr $c + 1`
done
) | tee unique_raion_features.csv

