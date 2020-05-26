#-----------------------------------------------------------------------------
# Parts of the original bashrc that I kept.
#-----------------------------------------------------------------------------

# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s lithist
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1024
HISTFILESIZE=20000
export IGNORE_SYSTEM_ALIASES=1

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

#-----------------------------------------------------------------------------
# Personal env
#-----------------------------------------------------------------------------

ssh_agent()
{   Restart_agent=0
   Agent=~/.ssh/agent_info
   if [ ! -f ${Agent} ] ## Agent file not present
   then
      Restart_agent=1
   else
      Pid=$(grep -i ssh_agent_pid ${Agent} | awk -F\; '{print $1}' | \
         awk -F= '{print $2}')
      ps -p ${Pid} > /dev/null 2>&1
      if [ $? -ne 0 ]
      then
         Restart_agent=1
      else
         . ${Agent}
      fi
   fi

   if [ ${Restart_agent} -ne 0 ]
   then
      /usr/bin/ssh-agent | head -2 > ${Agent}
      . ${Agent}
      echo ""; echo "You need to add the ssh keys manually!"
   fi
}

mcd()
{   Me=$(whoami)
   Host=$(hostname)
   Host=${Host%%\.*}
   cd $*
   Pwd=$(pwd)
   echo -n "]0;${Me}@${Host}:${Pwd}"
}

title()
{   echo -n "];${*}"
}

ctime()
{
   eval "perl -e '\$time = localtime($1); print \"\$time\\n\"'"
}

whenis()
{  if [ $# -eq 0 ]
   then
      perl -e 'print int(time()/86400) . "\n"'
   else
      eval "perl -e 'my (\$day, \$mon, \$year) = (localtime($1 * 86400))[3..5];\
         printf (\"%02d/%02d/%02d\n\", \$mon+1, \$day, \$year%100)'"
   fi
}

cdtmp()
{   dts=$(date +%y%m%d)
    mkdir -p -m 755 ~/working/temp/${dts}
    cd ~/working/temp/${dts}
}

ltree()
{   f=$1
   [[ ${#f} -eq 0 ]] && return
   ls -ld $f
   ltree ${f%/*}
}

ip2hex()
{
eval "perl -le '\$i=\"$1\"; \$i=~s/(\d+)\.?/sprintf(\"%02x\",\$1)/ge; print uc(\$i)'"
}

show_disks()
{   s=${1:-nap1151}
    ssh ${s} "xymon localhost 'xymondboard test=disk'" | \
    grep -e '|red|' -e '|yellow|' | awk -F\| '{print $1}'
}

rmpdir()
{     rm ${PSSH_OUTDIR}/*
}

cdpdir()
{     cd ${PSSH_OUTDIR}
}

showpssh()
{
  if [ $# -gt 0 ]
  then
    for h in ${PSSH_OUTDIR}/*
    do
      echo "###############################################################"
      echo "# ${h##*/} "
      echo "#=============================================================="
      cat ${h}
    done
  else
    for h in ${PSSH_OUTDIR}/*
    do
      printf "%-16s " ${h##*/}
      [[ -s ${h} ]] && cat ${h}  || echo ''
    done
  fi
}

#-----------------------------------------------------------------------------
# VCS 
#-----------------------------------------------------------------------------

gl()
{  git log --pretty=oneline --abbrev-commit $*
}

tags()
{ git tag -n | sort -V
}

#-----------------------------------------------------------------------------
# AWS functions
#-----------------------------------------------------------------------------

rhel_aws_amis()
{
  aws ec2 describe-images --owners 309956199498 \
  --query 'Images[*].[CreationDate,Name,ImageId]' \
  --filters "Name=name,Values=RHEL-7.?*GA*" --region us-east-2 \
  --output text | sort -r -k 1
}

list_instances()
{ 
  aws ec2 describe-instances --query \
    'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,PublicDnsName]' \
    --output text
}

terminate_instances()
{
  [[ $# -ne 1 ]] && return
  aws ec2 terminate-instances --instance-ids $1
}

#-----------------------------------------------------------------------------
# Env vars and aliases
#-----------------------------------------------------------------------------

export         PS1="# "
set -o vi
# unalias vi
alias ls="ls -F"
alias cd=mcd
alias more="less"
alias h="hostname"
alias rst2html="/usr/bin/rst2html.py"
# alias python=python3
# alias pip=pip3
export PATH=/usr/local/git/bin:${PATH}
# complete -C /home/dkoleary/.local/bin/aws_completer aws

umask 022
export EDITOR=vi
set -o vi
cd ${HOME}
# ssh_agent
