#! /bin/bash

function die {
cat > /dev/stderr <<-END
$1
END

exit 1; 
}

for i in "$@"; do
    if [[ "$i" == *.h ]]; then
        ctags -x --c-kinds=f $i
    elif [[ "$i" == *.c ]]; then
        lst=$(grep EXPORT_SYMBOL $i | perl -wnl -e 's/EXPORT_SYMBOL[^(]*\((.*)\).*/$1/; print')
        for f in $lst; do 
            # " $f" instead of "$f" to exclude internal function (i.e., __$f) from the list
            ctags -x --c-kinds=f $i | egrep " $f"
        done
    fi
done
