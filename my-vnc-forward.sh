#! /bin/sh

function die {
cat > /dev/stderr <<-END
$1
END

exit 1 
}

if (( $# < 2 )); then
    die "Usage: $0 <host> <remote N> [<local N>]"
fi

_host=$1
_rport=$2

if [[ "$3" ]]; then
    _lport=$3
else
    _lport=$_rport
fi

echo $_lport

ssh -N -L $((5900+_lport)):localhost:$((5900+_rport)) ${_host}
