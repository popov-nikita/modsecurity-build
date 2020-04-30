#!/bin/sh

set -x
set -u -e

if test "$#" -eq "1"; then
	conf_tpl="${1}"
else
	conf_tpl="${CONFIG_TEMPLATE}"
fi
test -f "$conf_tpl"

cd "${SERVER_ROOT}"
# Clean directory
find "." -mindepth 1 -maxdepth 1 -exec 'rm' '-r' '{}' \;

# Install docroot
umask 0000
mkdir -p -m 777 "${SERVER_DOCROOT}"

PROCESS_PARAMS="$(cat<<'EOF'

BEGIN {
	FS = "\\+\\+[_a-zA-Z][_a-zA-Z0-9]*\\+\\+";
}

(NF > 0) {
	cur_s = $0;
	cur_i = 1;
	fix_s = "";
	
	while (1) {
		match(cur_s, FS);
		if (!RSTART)
			break;
		varname = substr(cur_s, RSTART + 2, RLENGTH - 4);
		if (ENVIRON[varname] == "")
			next;
		fix_s = fix_s $cur_i ENVIRON[varname];
		cur_s = substr(cur_s, 1 + length($cur_i) + RLENGTH);
		cur_i++;
	}
	fix_s = fix_s $cur_i;

	print fix_s;
	next;
}

{
	print;
}

EOF
)"

awk "$PROCESS_PARAMS" "$conf_tpl" > "httpd.conf"

# Finally, run APACHE2. This should gracefully daemonize
/usr/apache2/bin/httpd -k start -d /www -f /www/httpd.conf

# Run shell for debug purposes
exec "/bin/sh"

exit 0
