#!/bin/bash

# sqlite3 expedia.sqlite3 <<EOF
#     DROP TABLE user
# EOF
# 
# sqlite3 expedia.sqlite3 <<EOF
#     CREATE TABLE user (
#         user_id VARCHAR(8),
#         bucket  VARCHAR(8),
#         PRIMARY KEY (user_id)
#     )
# EOF
# 

strip_header()
{
    for f in "$@"; do
        echo "breaking $f into head and remainder"
        head -n +1 "$f" > "$f".head
        head -n -2 "$f" > "$f".remainder
    done
}


for csvfile in user_id/user_id*.csv; do
    sqlitefile=`echo "$csvfile" | sed -e 's/.csv$/.sqlite3/'`
    trainfile=`echo "$csvfile" | sed -e 's/\/user_id/\/train/'`
    echo $csvfile "->" $sqlitefile $trainfile

    rm -f "$sqlitefile" "$trainfile"

    if [ ! -e "$csvfile".head ]; then
        strip_header "$csvfile"
    fi

    sqlite3 "$sqlitefile" <<EOF
CREATE TABLE user (
    user_id VARCHAR(8),
    PRIMARY KEY (user_id)
);
.mode csv
.import $csvfile.remainder user
attach database 'expedia.sqlite3' as expedia;
.head on
.output $trainfile
select * from expedia.train NATURAL JOIN user;
EOF


    # cleanup
    rm -f "$filename.head" "$filename.remainder"
done
