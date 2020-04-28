#!/bin/sh

set -x
set -u -e

cd "$(dirname "$0")"
HOST_RO_DIR="$(realpath "ro-data.d")"
HOST_RW_DIR="$(realpath "rw-data.d")"

_GET_ENV="$(cat<<'EOF'
BEGIN {
	FS = " ";
}

($1 == "ENV") && (NF == 3) {
	all_vars[$2] = $3;
}

END {
	readonly_printed = 0;
	for (var in all_vars) {
		if (!readonly_printed) {
			printf "readonly";
			readonly_printed = 1;
		}
		printf " %s=%s", var, all_vars[var];
	}
	printf "\n";
}
EOF
)";

eval "$(awk "${_GET_ENV}" Dockerfile)"

SHOULD_PRUNE="0"

while getopts ":p" OPT; do
	case "$OPT" in
	p)
		if test "$(docker images -q "$IMAGE_NAME")" != ""; then
			SHOULD_PRUNE="1"
		fi
		;;
	*)
		printf "Unknown option: %s\n" "$OPTARG"
		exit 1
		;;
	esac
done

if test "$SHOULD_PRUNE" -eq "1"; then
	docker rmi -f "$IMAGE_NAME"
fi

if test "$(docker images -q "$IMAGE_NAME")" = ""; then
	docker build -t "$IMAGE_NAME" .
fi

docker run                                                                                      \
       --mount type=bind,src="$HOST_RO_DIR",dst="$DOCKER_RO_DIR",ro=true,bind-nonrecursive=true \
       --mount type=bind,src="$HOST_RW_DIR",dst="$DOCKER_RW_DIR",bind-nonrecursive=true         \
       -h "${IMAGE_NAME}.local" "$IMAGE_NAME"

exit 0
