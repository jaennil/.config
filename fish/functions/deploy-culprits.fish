function deploy-culprits -d "find deploy branches that break a build: stale base, unrelated history, file conflict"
    if test (count $argv) -lt 1
        echo "usage: deploy-culprits <branch1,branch2,...> [file]" >&2
        echo "       file по умолчанию .docker/dev/consul_kv_dev.json" >&2
        return 1
    end

    if not git rev-parse --show-toplevel >/dev/null 2>&1
        echo "не git-репозиторий" >&2
        return 1
    end

    set -l file .docker/dev/consul_kv_dev.json
    if test (count $argv) -ge 2
        set file $argv[2]
    end

    # master ушёл больше чем на столько коммитов от точки ветвления - ветка рискует
    # не смержиться в shallow-клоне jenkins с "refusing to merge unrelated histories"
    set -l stale_limit 500

    git fetch origin --quiet

    set -l branches
    for b in (string split , $argv[1] | string trim)
        if not git rev-parse --verify --quiet origin/$b >/dev/null
            echo "?? $b (нет на origin)" >&2
            continue
        end
        set -a branches $b
    end
    test (count $branches) -gt 0; or return 1

    set -l master_root (git rev-list --max-parents=0 origin/master | head -1)

    echo "── давность точек ветвления ─────────────────────────────────"
    set -l stale
    for b in $branches
        set -l mb (git merge-base origin/master origin/$b 2>/dev/null)
        if test -z "$mb"
            printf "  %-34s %s\n" $b "НЕТ ОБЩЕГО ПРЕДКА с master"
            set -a stale $b
            continue
        end

        set -l root (git rev-list --max-parents=0 origin/$b | head -1)
        set -l date (git log -1 --format=%ad --date=short $mb)
        set -l behind (git rev-list --count $mb..origin/master)

        set -l mark ""
        if test $behind -gt $stale_limit
            set mark "  ← отстала, риск unrelated histories в shallow-клоне"
            set -a stale $b
        end
        if test "$root" != "$master_root"
            set mark "$mark  ← другой корневой коммит"
            set -a stale $b
        end

        printf "  %-34s base %s %s  master +%-5s%s\n" $b (string sub -l 9 $mb) $date $behind $mark
    end

    echo
    echo "── симуляция мержа в порядке сборки ─────────────────────────"
    set -l wt (mktemp -d)
    set -l failed
    if git worktree add -q --detach $wt origin/master 2>/dev/null
        for b in $branches
            set -l out (git -C $wt merge --no-edit origin/$b 2>&1)
            if test $status -eq 0
                printf "  ok    %s\n" $b
            else
                printf "  FAIL  %-30s %s\n" $b (string join ' | ' $out | string sub -l 120)
                set -a failed $b
                git -C $wt merge --abort 2>/dev/null
            end
        end
        git worktree remove -f $wt 2>/dev/null
    else
        echo "  не удалось создать worktree, пропускаю" >&2
    end
    rm -rf $wt 2>/dev/null

    echo
    echo "── трогают $file ───────────────"
    set -l touching
    for b in $branches
        if git diff origin/master...origin/$b --name-only 2>/dev/null | grep -qF $file
            echo "  $b"
            set -a touching $b
        end
    end
    test (count $touching) -gt 0; or echo "  никто"

    echo
    echo "── итог ─────────────────────────────────────────────────────"
    if test (count $failed) -gt 0
        echo "  мерж падает: "(string join ', ' $failed)
    end
    if test (count $stale) -gt 0
        echo "  подозрительные по давности: "(string join ', ' $stale)
        echo "  лечится вливанием master в ветку либо исключением её из сборки"
    end
    if test (count $failed) -eq 0 -a (count $stale) -eq 0
        echo "  чисто: локально всё мержится, свежих подозрений нет"
    end
end
