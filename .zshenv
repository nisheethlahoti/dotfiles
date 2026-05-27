typeset -U path

for p in /opt/homebrew/sbin /opt/homebrew/bin ~/.cargo/bin ~/.local/bin ; do
  [ -d $p ] && path=($p $path)
done
path=("${(u)path[@]}")
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
