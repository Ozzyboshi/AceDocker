# --- Begin sh script ---

set -e

usage () {
	echo Usage: incbin input.bin output.h symbolname
	exit 1
}

[ -z "$1" ] && usage
[ -z "$2" ] && usage
[ -z "$3" ] && usage
bytes=`od -An -t x1 -v "$1"`

(
	echo "/* Generated by incbin_fast */"
	echo
	echo "#include <stddef.h>"
	echo
	echo "__attribute__((fast)) const unsigned char $3_data_fast[] = {"

	offset=0 ; count=16
	for val in $bytes ; do
		if [ $count -eq 16 ] ; then
			if [ $offset -ne 0 ] ; then
				echo ,
			fi
			printf "/*%08x*/ " $offset
			count=0
		else
			echo -n ,
		fi
		echo -n 0x$val

		offset=$(($offset+1)) ; count=$(($count+1))
	done
	echo
	echo "};"
	echo
	echo "const size_t $3_size = sizeof($3_data);"
) > "$2"

