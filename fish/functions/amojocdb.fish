function amojocdb
    set -l env $argv[1]
    set -l db $argv[2]
    set -l host

    if test -z "$env"
        echo "usage: amojocdb en|ru [database]" >&2
        return 1
    end

    switch $env
        case ru
            set host 10.13.246.54
        case en
            set host 10.13.246.60
        case '*'
            echo "amojocdb: unknown environment '$env' (use en or ru)" >&2
            return 1
    end

    if test -z "$db"
        set db amojo_core
    end

    mariadb --ssl=0 -h $host -u amojo -pamojo $db
end
