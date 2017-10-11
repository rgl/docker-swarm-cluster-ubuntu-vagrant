#!/bin/bash
set -eux

# prevent apt-get et al from asking questions.
# NB even with this, you'll still get some warnings that you can ignore:
#     dpkg-preconfigure: unable to re-open stdin: No such file or directory
export DEBIAN_FRONTEND=noninteractive

# update the package cache.
apt-get update

# install jq.
apt-get install -y jq

# install vim.
apt-get install -y --no-install-recommends vim
cat >/etc/vim/vimrc.local <<'EOF'
syntax on
set background=dark
set esckeys
set ruler
set laststatus=2
set nobackup
EOF

# configure the shell.
cat >/etc/profile.d/login.sh <<'EOF'
[[ "$-" != *i* ]] && return
export EDITOR=vim
export PAGER=less
alias l='ls -lF --color'
alias ll='l -a'
alias h='history 25'
alias j='jobs -l'
EOF

cat >/etc/inputrc <<'EOF'
set input-meta on
set output-meta on
set show-all-if-ambiguous on
set completion-ignore-case on
"\e[A": history-search-backward
"\e[B": history-search-forward
"\eOD": backward-word
"\eOC": forward-word
EOF

# configure the motd.
# NB this was generated at http://patorjk.com/software/taag/#p=display&f=Big&t=docker%20swarm.
#    it could also be generated with figlet.org.
cat >/etc/motd <<'EOF'

      _            _
     | |          | |
   __| | ___   ___| | _____ _ __   _____      ____ _ _ __ _ __ ___
  / _` |/ _ \ / __| |/ / _ \ '__| / __\ \ /\ / / _` | '__| '_ ` _ \
 | (_| | (_) | (__|   <  __/ |    \__ \\ V  V / (_| | |  | | | | | |
  \__,_|\___/ \___|_|\_\___|_|    |___/ \_/\_/ \__,_|_|  |_| |_| |_|


EOF
