#!/bin/bash - 

_progname="$(basename $0)"
_ver="0.1.1-dev"
_author="Wei Peng <me@1pengw.com>"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

_qualifier_default="DEBUGINFO"

declare -a _kconfig
_kconfig=()

function showhelp () {
    cat <<END
$_progname: Build Arch Linux kernel packages from Arch Build System (ABS) with selected configs.
Version: $_ver
Author: $_author

$_progname [-c|--config=<config>]* [-q|--qualifier=<qualifier>]
    [-e|--editor=<editor>] [-d|--diff=<differ>]
    [-a|--abs] [-m|--makepkg]
    [-h|--help] [-v|--verbose]
    [--] [<makepkg args>]

-c	--config		Kconfigs to merge; can be multiple (DEFAULT: With CONFIG_DEBUG_INFO).
-q	--qualifier		Package name qualifier (DEFAULT: $_qualifier_default).
-e	--editor		Edit build files as they are generated.
-d	--diff			Diff generated build files with baseline.
-a	--abs			Get baseline from Arch Build System (ABS).
-m	--makepkg		Start makepkg.
-h	--help			Help, and you are reading it.
-v	--verbose		Verbose.	
END
}

#
# https://misc.flogisoft.com/bash/tip_colors_and_formatting
#
TERM_NORMAL='\e[0m'
TERM_BOLD='\e[1m'
TERM_DIM='\e[2m'
TERM_UNDERLINE='\e[4m'
TERM_BLINK='\e[5m'

TERM_FOREGROUND_DEFAULT='\e[39m'
TERM_FOREGROUND_RED='\e[31m'
TERM_FOREGROUND_GREEN='\e[32m'
TERM_FOREGROUND_YELLOW='\e[33m'
TERM_FOREGROUND_BLUE='\e[34m'
TERM_FOREGROUND_MAGENTA='\e[35m'
TERM_FOREGROUND_CYAN='\e[36m'

TERM_FOREGROUND_NORMAL=$TERM_FOREGROUND_DEFAULT
TERM_FOREGROUND_WARNING=$TERM_FOREGROUND_YELLOW
TERM_FOREGROUND_ERROR=$TERM_FOREGROUND_RED

function vecho () { # verbose echo
    local level=${1:-0}

    (( _verbose > level )) && {
        cat - | while IFS= read -r line; do
            echo -e $line
        done
    }
}

function getbin () { # get binary on path (best effort)
    local bin=${1:-bash}
    shift
    local pkg=${1:-bash}
    shift

    type "$bin" >/dev/null 2>&1 || {
        sudo pacman -S "$pkg" --noconfirm --needed
    } || type "$bin" >/dev/null 2>&1 || {
        >&2 echo -e "${TERM_FOREGROUND_ERROR}ERROR: Please install package $pkg, which has $bin.${TERM_FOREGROUND_DEFAULT}"
        exit 1
    }
}

#
# Parsing command-line arguments.
#

_options=$(getopt -n "$_progname" -o q:e:d:amhv -l qualifier:,editor:,diff:,abs,makepkg,help,verbose -- "$@")
[ $? -eq 0 ] || {
    showhelp >&2
    exit 1
}

eval set -- "$_options"
while true; do
    case "$1" in
        -c|--config)
            shift
            _kconfig+=("$1")
            ;;
        -q|--qualifier)
            shift
            _qualifier=$1
            ;;
        -e|--editor)
            shift
            _editor=$(type -p "$1")
            [[ -x "$_editor" ]] || _editor=$(type -p "${EDITOR:-vim}")
            [[ -x "$_editor" ]] || _editor=$(type -p "vi")
            [[ -x "$_editor" ]] || unset _editor
            ;;
        -d|--diff)
            shift
            _differ=$(type -p "$1")
            [[ -x "$_differ" ]] || _differ=$(type -p "${DIFF:-bcompare}")
            [[ -x "$_differ" ]] || _differ=$(type -p "diff")
            [[ -x "$_differ" ]] || unset _differ
            ;;
        -a|--abs)
            exec 3>&1 1>/dev/null # temporarily suppress stdout
            _bin="asp"
            _pkg="asp"
            getbin "$_bin" "$_pkg"
            "$_bin" checkout linux >/dev/null
            unset _bin _pkg
            _trunkpath="linux/trunk"
            [[ -r "$_trunkpath/PKGBUILD"  ]] || { >&2 echo "Cannot checkout linux from ABS."; exit 1; }
            pushd "$_trunkpath" || { >&2 echo "Fail to enter $_trunkpath."; exit 1; }
            exec 1>&3 # restore stdout
            ;;
        -m|--makepkg)
            ((_makepkg++))
            ;;
        -h|--help)
            showhelp
            exit 0
            ;;
        -v|--verbose)
            ((_verbose++))
            ;;
        --)
            shift
            break
            ;;
    esac
    shift
done

#
# Fill in defaults.
#

# Default _kconfig.
[[ ${#_kconfig[@]} -eq 0 ]] && {
    _defconfig=$(mktemp /tmp/archlinux-linux_config_debug.XXXXXX);
    echo '
CONFIG_KPROBES=y
CONFIG_KPROBES_SANITY_TEST=n
CONFIG_KPROBE_EVENT=y
CONFIG_NET_DCCPPROBE=m
CONFIG_NET_SCTPPROBE=m
CONFIG_NET_TCPPROBE=y
CONFIG_DEBUG_INFO=y
CONFIG_DEBUG_INFO_REDUCED=n
CONFIG_X86_DECODER_SELFTEST=n
CONFIG_DEBUG_INFO_VTA=y
' > "$_defconfig";
    [[ -r "$_defconfig" ]] || { >&2 echo "Fail to create default config."; exit 1; }
    _kconfig=("$_defconfig")
}

# Default _qualifier.
_qualifier=${_qualifier:-$_qualifier_default}

# Default _qualifier.
[[ _verbose > 0 ]] || exec 3>&1 1>/dev/null # suppress stdout if not verbose

#
# Sanity check.
#

vecho 0 <<END
${TERM_BOLD}config${TERM_NORMAL}: $_kconfig
${TERM_BOLD}qualifier${TERM_NORMAL}: $_qualifier
${TERM_BOLD}editor${TERM_NORMAL}: $_editor
${TERM_BOLD}differ${TERM_NORMAL}: $_differ
${TERM_BOLD}makepkg${TERM_NORMAL}: $_makepkg
${TERM_BOLD}verbose${TERM_NORMAL}: $_verbose
END

[[ -z "$CPATH" ]] || vecho 0 <<END
${TERM_FOREGROUND_WARNING}WARNING: CPATH is defined as $CPATH${TERM_FOREGROUND_DEFAULT}
END

[[ -z "$LD_LIBRARY_PATH" ]] || vecho 0 <<END
${TERM_FOREGROUND_WARNING}WARNING: LD_LIBRARY_PATH is defined as $LD_LIBRARY_PATH${TERM_FOREGROUND_DEFAULT}
END

_file="PKGBUILD"
[[ -r "$_file" ]] || { >&2 echo "Cannot read $_file"; exit 1; }
_file="config"
[[ -r "$_file" ]] || { >&2 echo "Cannot read $_file"; exit 1; }

_PKGBUILD="PKGBUILD.${_qualifier}"
_config="config.${_qualifier}"

#
# $_PKGBUILD
#

perl -wpl -e "s|^(\\s*pkgbase=\\s*\\S*)(.*)\$|\$1-${_qualifier}\$2|; s|^(\\s*options=).*\$|\$1('!strip')|; s|^(\\s*)config\\b(.*)\$|\$1${_config}\$2|; s|^(\\s*cp\\s*\\.\\./)config\\b(.*)\$|\$1${_config}\$2|;" "PKGBUILD" > "$_PKGBUILD"
[[ -x "$_editor" ]] && "$_editor" "$_PKGBUILD"
vecho 0 <<END
Patched PKGBUILD into $_PKGBUILD.
END

#
# $_config
#

cp -f config "$_config"
_mergeconfig=".config" # merge_config.sh writes to .config.
ln -sf "$_config" "$_mergeconfig" 
"${DIR}/scripts/merge_config.sh" -m "config" "${_kconfig[@]}" >/dev/null
[[ -h "$_mergeconfig" ]] && rm -f "$_mergeconfig"
[[ -x "$_editor" ]] && "$_editor" "$_config"
vecho 0 <<END
Merged Kconfig into $_config.
END

#
# Update package checksums.
#

_bin="updpkgsums"
_pkg="pacman-contrib"
getbin "$_bin" "$_pkg"
"$_bin" "$_PKGBUILD" 2>/dev/null || { >&2 echo "Failed to update package checksums."; exit 1; }
unset _bin _pkg
vecho 0 <<END
Updated source checksums in $_PKGBUILD.
END

#
# Diff.
#

[[ -x "$_differ" ]] && "$_differ" "PKGBUILD" "$_PKGBUILD"
[[ -x "$_differ" ]] && "$_differ" "config" "$_config"

#
# Build packages with makepkg.
#

(( _makepkg > 0 )) && makepkg -s -p "$_PKGBUILD" "$@"


#
# Finalize.
#

[[ -n "$_trunkpath" ]] && popd >/dev/null
