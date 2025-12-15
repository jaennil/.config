function g --wraps=git --description 'alias g=git'
  if test (count $argv) -ge 2; and test "$argv[1]" = "c" -o "$argv[1]" = "commit"
    git commit -m "$argv[2..-1]"
  else
    git $argv
  end
end
