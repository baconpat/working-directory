#echo 'TODO'
#echo ' - remove aliases when slots are set to .'
#echo ' - only have wd* (retr) aliases for filled slots'
#echo ' - consider replacing wdretr with just cd $WD${i} ??'
#echo ' - consider allowing "diskless" mode that uses only env. vars'
#echo " - add prompt for wdc when WDC_ASK is set"
#echo " - allow schemes with spaces in the name"

# If no WDHOME is set, make it the default of ~/.wd
if [ -z "$WDHOME" ]
then
  export WDHOME="$HOME/.wd"
  echo "Using $WDHOME as \$WDHOME."
fi

function _stored_scheme_name() {
  echo $(cat "$WDHOME/current_scheme")
}

function _stored_scheme_filename() {
  echo "$WDHOME/$(_stored_scheme_name).scheme"
}

function _stored_scheme() {
  cat $(_stored_scheme_filename)
}

function _env_scheme_filename() {
  echo "$WDHOME/$WDSCHEME.scheme"
}

function _set_stored_scheme() {
  echo $WDSCHEME > "$WDHOME/current_scheme"
}

function _create_wdscheme() {
  echo "Creating new scheme $WDSCHEME"
  mkdir -p $WDHOME
  _set_stored_scheme
  echo -e ".\n.\n.\n.\n.\n.\n.\n.\n.\n.\n" > $(_env_scheme_filename)
}

function _init_wdscheme() {
  if [ -f "$WDHOME/current_scheme" ]
  then
    if [ "$(_stored_scheme_filename)" != "$(_env_scheme_filename)" ] # we have a diff. scheme stored
    then
      echo "Cloning $(_stored_scheme_filename) new scheme $WDSCHEME"
      cp "$(_stored_scheme_filename)" "$(_env_scheme_filename)" # clone it
      _set_stored_scheme
    fi
  else
    _create_wdscheme
  fi
}

function _load_wdenv() {
  local slots _ifs_tmp i
  _ifs_tmp=$IFS
  IFS=$'\n'
  slots=( $(cat $(_env_scheme_filename)) )
  for i in 0 1 2 3 4 5 6 7 8 9
  do
    if [ "${slots[$i]}" != "." ]
    then
      export WD${i}="${slots[$i]}"
    else
      unset WD${i}
    fi
  done
  IFS=$_ifs_tmp
}

# If there is no valid current scheme, assume 'default'
if [ ! -f "$WDHOME/$WDSCHEME.scheme" -o -z "$WDSCHEME" ] # we don't have it in the env.
then
  #echo '* $WDSCHEME was invalid or not found'
  if [ -f "$WDHOME/current_scheme" ] # but we do have it stored
  then
    if [ -f $(_stored_scheme_filename) ]
    then
      #echo "Loading stored scheme: $(_stored_scheme_name)" 
      export WDSCHEME=$(_stored_scheme_name) # load the stored scheme into the env.
    else
      #echo '* current_scheme was there but did not contain a useable scheme name'
      _create_wdscheme
    fi
  else
    echo "No scheme set, using 'default'."
    export WDSCHEME=default
  fi
#else
  #echo "* already have scheme: $WDSCHEME"
fi

if [ -f "$WDHOME/current_scheme" ]
then
  # load current scheme slots
  _load_wdenv                                      
else
  # Store the scheme file if it's not already there
  _init_wdscheme
fi

function wdscheme() {
  if [ -z "$1" ]
  then
    echo "$WDSCHEME"
  else
    export WDSCHEME="$1"
    if [ -f "$WDHOME/${1}.scheme" ]
    then
      #echo "* already have this schema"
      _load_wdenv
      _set_stored_scheme
    else
      #echo "* new schema"
      _init_wdscheme
    fi
    
  fi
}

function _wdschemecomplete() {
  local cur schemedir origdir
  origdir=${PWD}
  schemedir=${WDHOME}
  COMPREPLY=()
  cur=${COMP_WORDS[COMP_CWORD]}
  cd ${schemedir}
  COMPREPLY=( $( compgen -G "${cur}*.scheme" | sed 's/\.scheme//g') )
  #COMPREPLY=${COMPREPLY[@]%.scheme}
  cd ${origdir}
}
complete -o nospace -F _wdschemecomplete wdscheme

# Function to store directories 
function wdstore() {
  local slot dir slots _ifs_tmp i j
  if [ -z "$1" ]
  then
    # must be trying to store into slot 0
    slot="0"
  else
    slot=$1
  fi

  if [ -z "$2" ]
  then
    # one argument means store current dir in given slot
    dir="$(pwd)"
  else
    dir="$2"
  fi
  
  #echo "* wdstore ${slot}: ${dir}"

# Read the existing slots from the scheme file
  _ifs_tmp=$IFS
  IFS=$'\n'
  slots=( $(cat $(_env_scheme_filename)) )
  #(( j = $slot + 1 ))
#echo 1
#set|grep ^slots
# Store the specified dir into the specified slot
  slots[$slot]="$dir"
#echo 2
#set|grep ^slots
# Write all slots back to the scheme file
  #for (( i = 0 ; i < ${#slots[@]} ; i++ ))
  for i in 0 1 2 3 4 5 6 7 8 9
  do
    (( j = $i + 1 ))
    if [ ! ${slots[$i]} == '' ]
    then
      echo "${slots[$i]}"
    else
      echo "."
    fi

  done > $(_env_scheme_filename)
  IFS=$_ifs_tmp                                      
#echo 3
#set|grep ^slots

# Update the alias for the new slot
  alias wd${slot}="wdretr $slot"
# Store the new slot contents into the env.
  export WD${slot}="$dir"
}

function wdretr() {
  local slot slots _ifs_tmp
  if [ -z "$1" ]
  then
    slot="0"
  else
    slot="$1"
  fi

  _ifs_tmp=$IFS
  IFS=$'\n'
  slots=( $(cat $(_env_scheme_filename)) )
  #(( slot = $slot + 1 ))
  #echo "* wdretr ${slot}: cd ${slots[$slot]}"
  if [ ! ${slots[$slot]} == '.' ]
  then
    cd ${slots[$slot]}
  fi
  IFS=$_ifs_tmp
}

function wdl() {
  local slots _ifs_tmp i j
  _ifs_tmp=$IFS
  IFS=$'\n'
  slots=( $(cat $(_env_scheme_filename)) )
  IFS=$_ifs_tmp                                      
  # if [ "- - - - - - - - - -" == "$slots" ]
  # then
    # for i in 0 1 2 3 4 5 6 7 8 9
    # do
      # echo "$i"
    # done
  # else
    for j in 0 1 2 3 4 5 6 7 8 9
    do
      #(( j = $i - 1 ))
      if [ "${slots[$j]}" != "." ]
      then
        echo "${j} ${slots[$j]}"
      else
        echo "${j}"
      fi
    done
  # fi
#echo 5
#set|grep ^slots
}

function wdc() {
  #if [ -z $WDC_ASK ]
  #then
  #  > $(_env_scheme_filename)
  #else
    #> $(_env_scheme_filename)
  echo -e ".\n.\n.\n.\n.\n.\n.\n.\n.\n.\n" > $(_env_scheme_filename)
  _load_wdenv
  #fi
}

alias wds='wdstore 0'
for i in 0 1 2 3 4 5 6 7 8 9
do
  alias wds$i="wdstore $i"
done

#ls_alias=`alias ls 2> /dev/null`
#if [ ! -z $ls_alias ]
#then
#  unalias ls
#fi
  
alias wd='wdretr 0'
for i in 0 1 2 3 4 5 6 7 8 9
do
  alias wd$i="wdretr $i"
done

# function _wdschemecomplete()
# {
		# COMPREPLY=()
		# cur=${COMP_WORDS[COMP_CWORD]}		
		# COMPREPLY=( $( compgen -d "$WDHOME/$cur"|grep -v '/current$'|cut -b $((${#WDHOME}+2))-) )
# }
# complete -o nospace -F _wdschemecomplete wdscheme
 
#if [ ! -z $ls_alias ]
#then
#  alias ls=$ls_alias
#fi