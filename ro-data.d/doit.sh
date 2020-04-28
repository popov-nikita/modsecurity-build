#!/bin/sh

set -x
set -u -e

find "${DOCKER_RW_DIR}" -mindepth 1 -maxdepth 1 -exec 'rm' '-r' '{}' \;
cp -R "${MODSECURITY_TARGZ%.tar.gz}" "${DOCKER_RW_DIR}"
cd "${DOCKER_RW_DIR}/${MODSECURITY_TARGZ%.tar.gz}"
# Fix permissions.
for file in $(find . \( -type d -o -type f \) -print); do
	perms="$(stat -c '%a' "$file")"
	urwx="${perms%??}"
	perms="${urwx}${urwx}${urwx}"
	chmod "$perms" "$file"
done

exit 0
