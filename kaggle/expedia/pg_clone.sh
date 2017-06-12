#!/bin/sh

# Pull missing tables from remote system.
# DOES NOT do anything for tables that already exist!

remote=r@fanny
dbname=expedia

psql -Atc "select tablename from pg_tables" $dbname | sort > /tmp/local_tables
ssh $remote psql -Atc '"select tablename from pg_tables"' $dbname | sort > /tmp/remote_tables

# OK, what's missing is these:
comm -1 -3 /tmp/local_tables /tmp/remote_tables > /tmp/missing_tables

echo "missing tables are at /tmp/missing_tables"
echo "please edit now if desired, then press return."
read ans

for tblname in `cat /tmp/missing_tables`; do
    echo "Copying $tblname"
    ssh -C $remote pg_dump -Fc -t $tblname $dbname | pg_restore -O -d $dbname

    # allow gracefull shutdown.
    if [ ! -e /tmp/missing_tables ]; then
	echo "shutting down prematurely after table $tblname"
	exit 1
    fi
    
done
