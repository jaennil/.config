function amojosdb
    set -l env $argv[1]
    set -l db $argv[2]
    set -l host
    set -l allowed

    if test -z "$env"
        echo "usage: amojosdb en|ru <database>" >&2
        return 1
    end

    switch $env
        case ru
            set host 10.13.246.54
            set allowed amojo_core amojo_shard1 amojo_shard2
        case en
            set host 10.13.246.60
            set allowed amojo_core amojo_shard1
        case '*'
            echo "amojosdb: unknown environment '$env' (use en or ru)" >&2
            return 1
    end

    if test -z "$db"
        echo "amojosdb: missing database name" >&2
        echo "available for $env: "(string join ", " $allowed) >&2
        return 1
    end

    if not contains -- $db $allowed
        echo "amojosdb: database '$db' is not available for $env" >&2
        echo "available for $env: "(string join ", " $allowed) >&2
        return 1
    end

    mariadb --ssl=0 -h $host -u amojo -pamojo $db
end
