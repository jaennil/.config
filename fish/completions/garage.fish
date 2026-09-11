function __garage_services
    garage main6 __complete-services (commandline -ct) 2>/dev/null
end

function __garage_branches
    set -l tokens (commandline -opc)
    if test (count $tokens) -ge 3
        garage main6 __complete-branches $tokens[3] 2>/dev/null
    end
end

complete -c garage -f
complete -c garage -n '__fish_use_subcommand' -a 'login' -d 'log in and save the session'
complete -c garage -n '__fish_use_subcommand' -a 'logout' -d 'forget the saved session'
complete -c garage -n '__fish_use_subcommand' -a 'main6' -d 'Deploy Main6 commands'
complete -c garage -n '__fish_use_subcommand' -a 'm6' -d 'alias for main6'
complete -c garage -n '__fish_use_subcommand' -a 'm' -d 'alias for main6'
complete -c garage -n '__fish_use_subcommand' -a 'completion' -d 'print shell completion script'
complete -c garage -n '__fish_use_subcommand' -a 'config' -d 'manage local garage-cli config'

complete -c garage -n '__fish_seen_subcommand_from main6 m6 m; and __fish_is_nth_token 2' -a 'ls' -d 'list services'
complete -c garage -n '__fish_seen_subcommand_from main6 m6 m; and __fish_is_nth_token 2' -a 'l' -d 'alias for ls'
complete -c garage -n '__fish_seen_subcommand_from main6 m6 m; and __fish_is_nth_token 2' -a 'deploy' -d 'trigger a main6 build'
complete -c garage -n '__fish_seen_subcommand_from main6 m6 m; and __fish_is_nth_token 2' -a 'd' -d 'alias for deploy'
complete -c garage -n '__fish_seen_subcommand_from main6 m6 m; and __fish_is_nth_token 2' -a 'add-branch' -d 'add a branch to main6'
complete -c garage -n '__fish_seen_subcommand_from main6 m6 m; and __fish_is_nth_token 2' -a 'ab' -d 'alias for add-branch'
complete -c garage -n '__fish_seen_subcommand_from main6 m6 m; and __fish_is_nth_token 2' -a 'delete-branch' -d 'remove a branch from main6'
complete -c garage -n '__fish_seen_subcommand_from main6 m6 m; and __fish_is_nth_token 2' -a 'db' -d 'alias for delete-branch'

complete -c garage -n '__fish_seen_subcommand_from main6 m6 m; and __fish_seen_subcommand_from ls l deploy d add-branch ab delete-branch db; and __fish_is_nth_token 3' -a '(__garage_services)'
complete -c garage -n '__fish_seen_subcommand_from main6 m6 m; and __fish_seen_subcommand_from deploy d add-branch ab delete-branch db; and __fish_is_nth_token 4' -a '(__garage_branches)'

complete -c garage -n '__fish_seen_subcommand_from completion' -a 'fish'
complete -c garage -n '__fish_seen_subcommand_from deploy d add-branch ab delete-branch db' -l yes -s y -d 'skip confirmation'
complete -c garage -n '__fish_seen_subcommand_from add-branch ab' -l deploy -s d -d 'also trigger a build'

complete -c garage -n '__fish_seen_subcommand_from config; and __fish_is_nth_token 2' -a 'set-repo' -d 'set a service -> local repo path override'
complete -c garage -n '__fish_seen_subcommand_from config; and __fish_is_nth_token 2' -a 'unset-repo' -d 'remove a service repo override'
complete -c garage -n '__fish_seen_subcommand_from config; and __fish_is_nth_token 2' -a 'list-repos' -d 'show configured overrides'
complete -c garage -n '__fish_seen_subcommand_from config; and __fish_is_nth_token 2' -a 'add-repo' -d 'add a service -> git remote, no code change'
complete -c garage -n '__fish_seen_subcommand_from config; and __fish_is_nth_token 2' -a 'remove-repo' -d 'remove that mapping'
complete -c garage -n '__fish_seen_subcommand_from config; and __fish_is_nth_token 2' -a 'list-repo-urls' -d 'show added mappings'
complete -c garage -n '__fish_seen_subcommand_from config; and __fish_is_nth_token 2' -a 'pull-repos' -d 'pre-clone/refresh every known repo mirror'
complete -c garage -n '__fish_seen_subcommand_from config; and __fish_is_nth_token 2' -a 'disable-ownership' -d 'turn off branch ownership highlighting'
complete -c garage -n '__fish_seen_subcommand_from config; and __fish_is_nth_token 2' -a 'enable-ownership' -d 'turn branch ownership highlighting back on'
complete -c garage -n '__fish_seen_subcommand_from config; and __fish_seen_subcommand_from set-repo unset-repo remove-repo; and __fish_is_nth_token 3' -a '(__garage_services)'
complete -c garage -n '__fish_seen_subcommand_from config; and __fish_seen_subcommand_from set-repo; and __fish_is_nth_token 4' -F
complete -c garage -n '__fish_seen_subcommand_from pull-repos' -l force -s f -d 'refresh repos even if already fresh'
