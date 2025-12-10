function tuna-inspect
    set -l port $argv[1]
    set -l subdomain $argv[2]

    mitmweb --mode reverse:http://localhost:$port@8082 &
    set -l pid $last_pid

    tuna http 8082 -s $subdomain

    kill $pid 2>/dev/null
end
