#!/bin/sh

set -x
set -u -e

cd "$(dirname "$0")"
HOST_RO_DIR="$(realpath "ro-data.d")"
HOST_RW_DIR="$(realpath "rw-data.d")"

# Extract ENV variables defined in Dockerfile, mark them as readonly
_ENV_REGEX='^[[:space:]]*ENV[[:space:]]+([_a-zA-Z][_a-zA-Z0-9]*)[[:space:]]+(.+)$'
eval "$(sed -n -E -e "s@${_ENV_REGEX}@readonly \1=\2@p" Dockerfile)"

SHOULD_PRUNE="0"
IS_INTERACTIVE="0"

while getopts ":pi" OPT; do
	case "$OPT" in
	p)
		if test "$(docker images -q "$IMAGE_NAME")" != ""; then
			SHOULD_PRUNE="1"
		fi
		;;
	i)
		IS_INTERACTIVE="1"
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

if test "$IS_INTERACTIVE" -eq "1"; then
	docker run                                                                                      \
	       -i -t                                                                                    \
	       --mount type=bind,src="$HOST_RO_DIR",dst="$DOCKER_RO_DIR",ro=true,bind-nonrecursive=true \
	       --mount type=bind,src="$HOST_RW_DIR",dst="$DOCKER_RW_DIR",bind-nonrecursive=true         \
	       -h "${IMAGE_NAME}.local" "$IMAGE_NAME"
else
	docker run                                                                                      \
	       --mount type=bind,src="$HOST_RO_DIR",dst="$DOCKER_RO_DIR",ro=true,bind-nonrecursive=true \
	       --mount type=bind,src="$HOST_RW_DIR",dst="$DOCKER_RW_DIR",bind-nonrecursive=true         \
	       -h "${IMAGE_NAME}.local" "$IMAGE_NAME"
fi

exit 0
