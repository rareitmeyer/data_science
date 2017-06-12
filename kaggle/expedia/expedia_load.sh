#!/bin/sh

strip_header()
{
    for f in "$@"; do
        echo "breaking $f into head and remainder"
        head -n +1 "$f" > "$f".head
        tail -n +2 "$f" > "$f".remainder
    done
}

rm -f expedia.sqlite3
sqlite3 expedia.sqlite3 < schema.sql

for data in destinations test train; do
    filename="$data.csv"
    #if [ -e "small_$filename" ]; then
    #    filename="small_$filename"
    #fi
    if [ ! -e "$filename" ]; then
        echo "Error, file $filename does not exist" 1>&2
        exit 1
    fi
    if [ ! -e "$filename".head ]; then
        strip_header "$filename"
    fi

    echo "loading $data"
    sqlite3 expedia.sqlite3  <<EOF
.mode csv
.import $filename.remainder $data
EOF

done




