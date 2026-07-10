function coresdb
    set -l shard $argv[1]

    if test -z "$shard"
        echo "usage: coresdb <shard_number>" >&2
        return 1
    end

    if not string match -qr '^[0-9]+$' -- $shard
        echo "coresdb: shard number must be numeric" >&2
        return 1
    end

    set -l host core-db-shard$shard-balancer.ru-0.dev.core.amosrv.ru
    set -l port (math 3305 + $shard)
    set -l db shard$shard

    mariadb --ssl=0 -h $host -P $port -u qcrm -p111111 $db
end
