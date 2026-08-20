function retry --description 'Rerun a command until it exits 0'
    argparse -s 'd/delay=' 'n/attempts=' q/quiet -- $argv
    or return 2

    if not set -q argv[1]
        echo 'usage: retry [-d seconds] [-n attempts] [-q] command...' >&2
        return 2
    end

    set -l delay 1
    test -n "$_flag_delay"; and set delay $_flag_delay

    # 0 means keep going until it works
    set -l max 0
    test -n "$_flag_attempts"; and set max $_flag_attempts

    set -l attempt 0
    while true
        set attempt (math $attempt + 1)

        $argv
        set -l code $status

        if test $code -eq 0
            if test -z "$_flag_quiet" -a $attempt -gt 1
                printf 'retry: succeeded on attempt %d\n' $attempt >&2
            end
            return 0
        end

        if test $max -gt 0 -a $attempt -ge $max
            printf 'retry: giving up after %d attempts, last status %d\n' $attempt $code >&2
            return $code
        end

        if test -z "$_flag_quiet"
            printf 'retry: attempt %d failed with status %d, retrying in %ss\n' $attempt $code $delay >&2
        end
        sleep $delay
    end
end
