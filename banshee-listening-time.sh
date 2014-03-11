#!/bin/bash

create_table() {
    sqlite3 time.db "CREATE TABLE IF NOT EXISTS time 
    (id INTEGER PRIMARY KEY, date TEXT UNIQUE, seconds INTEGER);"
}

insert_replace_time() {
    local seconds=$1
    sqlite3 time.db \
        "INSERT OR REPLACE INTO TIME (id, date, seconds) 
         VALUES ((select id from time where date=date('now', 'localtime')),
                date('now', 'localtime'), 
                COALESCE(((SELECT seconds FROM time 
                    WHERE date=date('now', 'localtime')) + $seconds), 
                    $seconds));"
}

convert_seconds() {
    (( h=${1}/3600 ))
    (( m=${1}%3600/60 ))
    (( s=${1}%60 ))
    printf "%02d:%02d:%02d\n" $h $m $s
}

main() {
    create_table
    seconds=0
    unix_time=`date +%s`

    while sleep 10; do
        current_unix_time=`date +%s`
        if ( pgrep banshee > /dev/null ); then
            if [ "$(banshee --query-current-state | cut -d ' ' -f2)" \
                = "playing" ]; then
                elapsed_seconds=$((current_unix_time - unix_time))
                seconds=$((seconds + elapsed_seconds))
                insert_replace_time $elapsed_seconds
                convert_seconds $seconds
            fi
        fi
        unix_time=$current_unix_time
    done
}

main
