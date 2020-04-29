# Sometimes, the server runs behind a device that processes SSL,
# such as a reverse proxy, load balancer or SSL offload appliance.
# When this is the case, specify the https:// scheme and the port number
# to which the clients connect in the ServerName directive to make sure
# that the server generates the correct self-referential URLs.
ServerName ++SERVER_NAME++
ServerRoot "++SERVER_ROOT++"

Listen 80

LoadModule security2_module /usr/modsecurity/lib/mod_security2.so

PidFile ++SERVER_PID_FILE++

<IfModule unixd_module>
        User ++SERVER_USER++
        Group ++SERVER_GROUP++
</IfModule>

<Directory "/">
    AllowOverride none
    Require all denied
</Directory>

DocumentRoot "++SERVER_DOCROOT++"
AccessFileName .htaccess

<Directory "++SERVER_DOCROOT++">
    Options None
    <IfModule dir_module>
        DirectoryIndex index.php index.html
    </IfModule>

    AllowOverride All
    Require all granted
</Directory>

<Files ".ht*">
    Require all denied
</Files>

ErrorLog "++SERVER_ERROR_LOG++"
LogLevel debug

<IfModule log_config_module>
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
    CustomLog "++SERVER_ACCESS_LOG++" combined
</IfModule>

<IfModule headers_module>
    #
    # Avoid passing HTTP_PROXY environment to CGI's on this or any proxied
    # backend servers which have lingering "httpoxy" defects.
    # 'Proxy' request header is undefined by the IETF, not listed by IANA
    #
    RequestHeader unset Proxy early
</IfModule>

<IfModule mime_module>
    TypesConfig /etc/mime.types
</IfModule>
