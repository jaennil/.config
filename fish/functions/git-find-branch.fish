function git-find-branch -d "Find the original feature/hotfix branch where a commit first appeared"
    if test (count $argv) -eq 0
        echo "Usage: git-find-branch <commit-hash>"
        return 1
    end

    set -l full (git rev-parse $argv[1] 2>/dev/null)
    or begin
        echo "error: invalid commit '$argv[1]'"
        return 1
    end

    set -l short (git rev-parse --short $full)
    echo "commit: "(git log --format="%h %ai %an — %s" -1 $full)
    echo ""

    # Step 1: branches whose tip IS this commit (most likely the original)
    set -l tips (git branch -a --points-at $full 2>/dev/null | sed 's/^[* ]*//' | string trim)
    set -l feature_tips
    for t in $tips
        if string match -qr '(feature|hotfix|fix|task|feat|bugfix)/' -- $t
            if not string match -q '*build*' -- $t
                set -a feature_tips $t
            end
        end
    end

    if test (count $feature_tips) -gt 0
        echo "branch tip = commit:"
        for b in $feature_tips
            echo "  $b"
        end
        return 0
    end

    # Step 2: all feature/hotfix branches containing the commit
    set -l all (git branch -a --contains $full 2>/dev/null | sed 's/^[* ]*//' | string trim)
    set -l candidates
    for b in $all
        if string match -qr '(feature|hotfix|fix|task|feat|bugfix)/' -- $b
            if not string match -q '*build*' -- $b
                set -a candidates $b
            end
        end
    end

    if test (count $candidates) -eq 0
        # Fallback: show build branches sorted by date (earliest = original)
        set -l build_branches
        for b in $all
            if string match -qr 'build_' -- $b
                set -a build_branches $b
            end
        end
        if test (count $build_branches) -gt 0
            echo "no feature/hotfix branch found. earliest build branch:"
            echo "  $build_branches[1]"
        else
            echo "no matching branches found"
        end
        return 1
    end

    # Step 3: sort candidates by distance (commits between our commit and branch tip)
    echo "feature/hotfix branches (by distance to tip):"
    set -l lines
    for b in $candidates
        set -l ref (string replace 'remotes/' '' -- $b)
        set -l dist (git rev-list --count $full..$ref 2>/dev/null; or echo 9999)
        set -a lines (printf '%06d %s' $dist $b)
    end

    printf '%s\n' $lines | sort | while read -l line
        set -l dist (string sub -l 6 -- $line | string replace -r '^0+' '')
        set -l branch (string sub -s 8 -- $line)
        test -z "$dist"; and set dist 0
        echo "  [$dist ahead] $branch"
    end
end
