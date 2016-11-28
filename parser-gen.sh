#! /bin/bash

debug(){
  while [ "$1" != "" ]; do
    case $1 in
      ENDL)
        echo ""
      ;;
      *)
        echo $1 = ${!1}
      ;;
    esac
    shift
  done
}

asd(){
    case "$@" in
      pack)
        shift 2;
        echo $1
      ;;
      unpack)
    esac
}

_countCommas(){
  local in="$@"
  local res="${in//[^,]}"
  if [ "$res" == "" ]; then 
    echo 0
  else
    echo "${#res}"
  fi
}

countArgs(){
  local in="$@"
  if [ "$in" == "" ]; then
    echo 0
  else
    echo $(( $(_countCommas $args) + 1 ))
  fi
}

_getArgs(){
  while [ "$1" != "" ]; do
    echo "local $1=\"\$1\"; shift"
    shift
  done
}

emitHeader(){
  local parseFnName=$1
  local variableName=$2
  echo "
function $parseFnName(){
  local numArgs=\$#
  local $variableName
  for (( $variableName=0; $variableName <= numArgs; ++$variableName)); do
    case \$1 in"
}

emitBody0(){
  eval "$(_getArgs fnName body)"
  echo "
      --$fnName)
        $body
      ;;"
}
emitBody1(){
  eval "$(_getArgs fnName body arg)"
  echo "
      --$fnName)
        local $arg=\"\$2\"
        shift
        $body
        ;;
      --$fnName=*)
        $arg=\"\${1#--$fnName=}\"
        $body
        ;;"
}

emitLocalDecl(){
  while [ "$1" != "" ]; do
    echo "
         local $1=\${_restArgs%,*}
         _restArgs=\${_restArgs#*,}"
    shift
  done
}

emitBodyMore(){
  eval "$(_getArgs fnName body args)"
  echo "
      --$fnName)
         local _restArgs=\$2
         shift"
  emitLocalDecl ${args//,/ }
  echo "
         $body"
  echo "
      ;;"
      
  echo "
      --$fnName=*)
         local _restArgs=\${1#--$fnName=}"
  emitLocalDecl ${args//,/ }
  echo "
         $body"
  echo "
      ;;"
}


emitFooter(){
  echo "
      *)
        # unrecognized
        return 1
      ;;
    esac
    shift
  done
}
"
}

genParser(){
  local pt decl body fnName args argsCount parserFnName

  parserTable=$1
  pt=${!parserTable}
    
  emitHeader $parserTable z
  while read line; do
    decl=${line%:*}
    body=${line#*:}
    fnName=${decl%(*}
    args=${decl#*(}; args=${args%)*}
    argsCount=$(countArgs $args)
#    debug line decl body fnName args argsCount ENDL
    if [ $argsCount == 0 ]; then
      emitBody0 $fnName "$body"
    elif [ $argsCount == 1 ]; then
      emitBody1 "$fnName" "$body" "$args"
    else
      emitBodyMore "$fnName" "$body" "$args"
    fi
  done <<< "$pt"
  emitFooter
}

DEBUG=0
myParser='asd(a):A=$a; echo "A=$a"
  zxc():ZXC=true; echo "ZXC=true"
  def(a,b):echo $a $b; echo "$a $b"
  debug():DEBUG=1'

eval "$(genParser myParser)"
myParser $@

if [ "$DEBUG" == "1" ]; then
# print generated parser
  genParser myParser
fi




: << COMMENT
function parse(){
  local numArgs=$#
  local i
  for (( i=0; i <= numArgs; ++i)); do
    echo arg[$i]=${!i}
  done
}

#parse $@
COMMENT