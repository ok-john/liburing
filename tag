#!/bin/bash
if [[ $EUID -eq 0 ]]; then echo "This script must not be run as root" && exit 1; fi
readonly __dir=$(dirname "$(realpath $0)") && cd $__dir
readonly __cmd=${1:-"__init"}
readonly __sub_cmd=${2:-"v"}
readonly __args=( "$@" )
readonly _secr="tag.actions.secret";
readonly VTAG="$__dir/.tag";
readonly MVAR="$VTAG/MVAR";
readonly MNOR="$VTAG/MNOR";
readonly RLSE="$VTAG/RLSE";

function _mul
{
	rm -rf fifo_mul && mkfifo fifo_mul &&
	local _x=$(( $1 )) &&
	local _y=$(( $2 )) &&
	local _z=$(( ${3:-1} )) &&
	local __v=$(( ${1:1} * ${2:2} )) &&
	local __y=$(( $_z - 1 )) && 
	cat <(echo "$__v") > fifo_mul &
	echo "$(cat fifo_mul)"
}

function _xor 
{
	local Gx=$(( $1 )) &&
	local Gy=$(( $2 )) &&
	local q=$(( ${3:-8} )) &&
	local p=$(( $Gx * $Gy )) &&
	local p=$(( $Gx * $Gy )) &&
	local n=$(( $p % $q )) &&
	echo $(( $Gx ^ $Gy ))
}

function xG
{
		_u=$((`libfcat rp -b 2`))
		_a=$((`libfcat rp -b 2`))
		_G=$((`libfcat rp -b 2`))
		_b=$((`libfcat rp -b 2`))
		_G=$(( `libfcat rp -b 2` ))
		y=$(( `libfcat rp -b 2` ))
		k=$(( `libfcat rp -b 2` )) 
		_functions=.xor.functions
		echo '#!/bin/bash' >  "$_functions"
		$(echo -e "echo\n ::(( "{$_u,$_a,$_G,$_b,$_G,$y,$k}" ^ "+{$_u,$_a,$_G,$_b,$_G,$y,$k}" )) " | tr -s " " | tr -d "\-+-" | awk '$0 ') | tr -d "echo" | sed -s 's/::/\necho $/g' >> $_functions && chmod 755 $_functions
		echo "" >> $_functions
		./$_functions | sha256sum | cut -c -64 > .checksum
}


function v
{
    	if [ -d "$VTAG" ]; then
        	echo "v$(cat $MVAR).$(cat $MNOR).$(cat $RLSE)"
    	fi
}

function y
{
    	v | tr -d "v" | tr "." "\n" 
}

function gen
{   
    	printf "v%s\n" {0..2}"."{0..16}"."{0..64}
}

function x521
{
		bash <(echo -e  "./tag _xor "{512..2}" "{2..${1:-512}}"\n")
}

function __init
{
    	if ! [ -d "$VTAG" ]; then
		if ! [ -d ".git" ]; then git init; fi
		mkdir -p $VTAG
		echo 0 > $MVAR
		echo 0 > $MNOR
		echo 0 > $RLSE &&
		rxor; fi && v && exit 0
}

function switch
{
	git switch -C "$(v)"
}

function inc
{
		_vf=${1:-"$RLSE"} &&
		i=$(cat $_vf) &&
		i=$(($((i))+1)) &&
		echo $i > $_vf &&
		./tag "switch"
}

function dec
{
	_vf=${1:-"$RLSE"} && 
	i=$(cat $_vf) &&
	i=$(($((i))-1)) && 
	echo $i > $_vf &&
	./tag "switch"
}

function incr 
{
	inc $RLSE
}

function decr 
{
	dec $RLSE
}

function incm
{
    	inc $MNOR
}

function decm
{
    	dec $MNOR
}

function incM
{
    	inc $MVAR
} 

function decM
{
    	dec $MVAR
}

function _by
{
	__iter="${__args[3]}"
	__iter4=${__args[4]}
	[[ "$__sub_cmd" != "_by"  || "${__args[3]}" == "" ]] || exit 0
	echo -e "about to $__sub_cmd $__args"
	echo "./tag $__args" | bash
	# echo -e "\n $__iter #"{0..1}+{2..$_upper_bound}"" | bash
}

function up 
{
	local   sign=${1:-"incr"}
	local	upper_bound="${2:-2}"
  	echo -e "./"{1..$(( $_upper_bound))}"" | bash
}

function down
{
	local   sign=${1:-"decr"}
	local	upper_bound="${2:-2}"
	echo -e "$./"{1..$_upper_bound}"" | bash
}


function ins
{
    
    	chmod 755 $0 && ls $0
}

function clear
{
    	rm -rf $VTAG
}

function curb
{
    	git branch --list | grep "* " | tr -d " *"
}

function is_in_remote
{
    	local branch=${1}
    	local existed_in_remote=$(git ls-remote --heads origin ${branch})

    	if [[ -z ${existed_in_remote} ]]; then
        	echo 0
    	else
        	echo 1
    	fi
}

function list
{
    	git branch --list
}

function is_in_local 
{
    	local branch=${1}
    	local existed_in_local=$(git branch --list ${branch})

    	if [[ -z ${existed_in_local} ]]; then
        	echo 0
    	else
        	echo 1
    	fi
}

function c
{
    	git add . && git commit -m "$RANDOM-${1:-auto}"
}

function u
{
	c
	git push -u origin "$(curb)"
}

function new-token
{
	if [ -f "$_secr" ]; then echo -e "\ntag access secret exists locally, manually remove with:\n\n\trm -rf $_secr\n" && exit 1; fi
	rm -rf fifo && mkfifo fifo
	echo "create a new token at: https://github.com/settings/tokens"
	read -p "new gh actions token: " _n_token
	echo $_n_token > fifo &
	openssl enc -aes256 -pbkdf2 -salt -in fifo -out $_secr && rm -rf fifo*
}

function fmt-sc
{
	echo ".$1.so"
}


function decrypt
{
	if ! [ -f "${1:-$_secr}" ]; then exit 0; fi
	openssl enc -aes256 -pbkdf2 -salt -d -in $_secr
}


function _decrypt
{
	openssl enc -aes256 -pbkdf2 -salt -d -in "$1"
}

function new-script
{
	rm -rf fifo && mkfifo fifo
	echo "" &>/dev/null &&
	read -p "name:" __o
	read -p "->" _n_token
	echo $_n_token > fifo &
	openssl enc -aes256 -pbkdf2 -salt -in fifo -out "$(fmt-sc $__o)" && rm -rf fifo*
}

function run
{
	_target="$1"
	_d="$(fmt-sc "$_target")"
	eval "$(_decrypt "$_d")"
}

function fmt-req
{
local _tkn=${2:-"NaN"}
		./.request
}

function release
{	
		local prefix=${1:-"stable"}
		local _vers="$(v)"
		local _tag="$prefix/$_vers"
		git fetch origin --tags &>/dev/null
		git switch -C "origin/main" &>/dev/null
		git pull &>/dev/null
		git tag $_tag &>/dev/null
		git push -u origin main &>/dev/null
		git push --tages &>/dev/null
		./.request $_tag "$(decrypt)" true true
}

function ci-release
{
		local prefix=${1:-"edge"}
		local _vers="$(v)"
		local _tag="$prefix/$_vers"
		git stash &>/dev/null
		git add . &>/dev/null
		git commit -m "ci edge-release $prefix $_vers" &>/dev/null
		dev "$prefix" &>/dev/null
		git fetch origin --tags &>/dev/null
		git tag $_tag &>/dev/null
		git push -u origin $_tag &>/dev/null
		./.request "$_tag" "${{ secrets.GITHUB_TOKEN }}" true true
}



function status 
{
		_brnch-"$(curb)"
		local _in_loc="$(is_in_local $_brnch)"
    		local _in_rem="$(is_in_remote $_brnch)"
		echo -e "branch-is-in-local:-$_in_loc"
		echo -e "branch-is-in-remote:-$_in_rem"
}

function dev
{
		local _brnch="${1:-dev}-$(v)"
		git fetch origin 
		git switch -C $_brnch
		git add . && git commit -m "init-$_brnch"
	 	git push --set-upstream origin "$_brnch"
}

function fetch
{
	local _brnch="$_vrs"
	git fetch origin $_
}

function it
{   
	dev
}

function align
{
	git restore --staged .
	git restore .
	git stash
	git fetch origin main
	git switch -C main 
	git pull --rebase
}

function tup
{
	echo git@github.com:ok-john/tag.git
}

function d
{
	echo "$__dir" "$__cmd" "$__args" && return
}


function D
{
	echo "$__dir" "$__cmd" "$__args"
	echo "$__dir/tag" "$__args"
}

$__init && $__cmd $__args
