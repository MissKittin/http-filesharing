#!/bin/bash
# Share files via HTTP
# 08.06.2019 - 11.06.2019

# HTTP filesharing
# 14-15.08.2019
# Usage: nohup http_filesharing.sh port > /dev/null 2>&1 &
# Login and password pre-defined below

# Check parameters
[ "$1" = '' ] && exit 1

# Define login and password
LOGIN='yourlogin'
PASSWORD='yourpassword'

# Make mountpoint workspace
[ -e /tmp/usb_drives ] || mkdir /tmp/usb_drives

# Simple functions
print_S1()
{
	# for php_optimize()
	echo -n "$1"
}
php_optimize()
{
	# This function renames " to ' and remove tabulations (compress file)
	while read -r line; do
		if [ "$(print_S1 $(echo -n "$line" | xargs -0))" = '//' ] || [ "$line" = '' ]; then
			# Remove comments and empty lines
			echo -n ''
		elif echo -n $line | grep -v '"' > /dev/null 2>&1 || echo -n $line | grep '<' > /dev/null 2>&1 || echo -n $line | grep '>' > /dev/null 2>&1; then
			# if isn't " in line or line has < or > html tag; then no changes
			echo "$line"
		else
			# Change " to '
			echo "$line" | sed -e 's/"/'"'"'/g'
		fi
	done
}


# Create php workspace
if [ ! -e /tmp/.http_filesharing ]; then
	mkdir /tmp/.http_filesharing || exit 1
fi

# Create PHP script and optimize it
echo '
	<?php
		// All of the following settings will be set by shell script

		// start session only for admin
		if(isset($_GET["admin"]))
			session_start();

		// set shared directory
		$SHARED_DIRECTORY="/tmp/usb_drives";

		// set login and password to admin
		$ADMIN_USER="'"$LOGIN"'"; // set
		$ADMIN_PASSWORD="'"$PASSWORD"'"; // set

		// little, but essential flag
		$NOT_EXISTS=false;

		// check if file exists
		!file_exists(rawurldecode(strtok($_SERVER["DOCUMENT_ROOT"] . $_SERVER["REQUEST_URI"], "?"))) ? $NOT_EXISTS=true : false;

		// do not process this if $NOT_EXISTS is true
		if(!$NOT_EXISTS)
		{
			// if url is regular file, abort this script
			if(!is_dir($SHARED_DIRECTORY . rawurldecode(strtok($_SERVER["REQUEST_URI"], "?"))))
				return false;
		}
	?>
	<!DOCTYPE html>
	<html>
		<head>
			<title>Shared files</title>
			<meta charset="utf-8">
			<style type="text/css">
				#header-text {
					text-align: center;
					font-weight: bold;
					font-size: 18pt;
					text-decoration: none;
					color: #000000;
					margin-left: 10px;
				}
				.folder {
					 list-style-image: url("data:image/png;base64,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")
				}
				.file {
					list-style-image: url("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4wYMEwUuJlNtNwAAA0hJREFUWMOdVjFLHEEU/vbtrKcEvLtO0MZG0bNVUtsddrYWFkLSaGWpJKSwS6wsEvCEK/wDIgE5UtiZdLb5ASIIEg2IhTuTInnL23dvdjUDw+4MO/u++b73vpkEop2cnHyemppaDiEghADvfemp50MIyPMcAPD09HR6dnb2fn9//zde0BI5OD8//zY3N7ccQgAAeO+R5zm890VnADzPY+99uLu7Sy4vL19vbW19fy4AkgMOnCR/cRERnHNI07ToRIQ0TYt5IuKeNJtNLC0tXfR6vXcAsLe393IAHFw+dbAkSYbAMbBms4lOp/Ph8PDwdGdnpxZECYAVnN8lC2maFiAsdlqtFhYWFlYYxMHBwcsYkF0CYuqJCFmWSfoLEM45NBoNtFotdDqdlaOjox+bm5vo9Xr/L4EliQwu5XDOYWxsrAAxPz+/2O/3v25sbJhyuBgAfo890zQtyeS9BxFhZGQEo6OjJRZnZ2e7/X7/y/r6+ttKAEQEKyf43XtfAsi5IPvNzQ2urq6QZRmyLEOj0UCSJJienn5zfHz8c21t7VMUgPd+KPksBvibEEJRFTx3fX2NwWBQWs++MTMz83F3d7fXbrd/bW9v2xIQUeFyMpBmRANzziHPc0xOTqLb7ZrO6b3HxMTEYHV1ddFkQFLJC6TGEoAGwVXSbrcxPj4edc/b29tXUQk0GCIqyRLLDw2IE1RKy1Ix2CgAKQH/jHfPi59TLTpB+dDKsqy6DE2zUKD0uVFXqvxdnudDzDmLevljGYglsZLRalyqRFQE199GnTDmBdqArHOjyj11fpgMxBKMG+dFLHmtPAFQgIgyYMlgHU6cF3qnco4DsXR6vvI4tt51MClJjLVYwj7rMIrdktgtpQR6rNfJwLUSyA/0zuTPhrJZ0CzHen0lA7yAk0wHkhcW+SO5W5mgdVUVvZTyDqxdaCDmT/8ZVyyPanNA66f1tQxJb8Ji0ZQuVoZaTyuhYuYjS07bceWdMFbfvCPpB5LmmBTW2loA2jxi5qMrRrMUq5LaMqwylJj5WPRXSVmbhLLW9TErDYUvGrFjvMoBKyWQJahp1bTHzEmfAbE8KTHw+PiI+/t702Tku2RCj+UVTl5MuT08PJQA/AFsdDEU9qilXgAAAABJRU5ErkJggg==");
				}
			</style>
		</head>
		<body>
			<div>
				<a id="header-text" href="/?admin">Shared files</a>
			</div>
			<div>
				<?php
					// admin
					if(isset($_GET["admin"]))
					{

						// logout
						if(isset($_POST["admin-logout"]))
						{
							$_SESSION["admin-logged"]=false;
							session_destroy();
							echo "<meta http-equiv=\"refresh\" content=\"0\"></div></body></html>";
							exit();
						}

						// logged and displayed
						if(isset($_SESSION["admin-logged"]))
						{
							if($_SESSION["admin-logged"])
							{
								if(isset($_POST["mount"]))
									shell_exec("/tmp/.http_filesharing/mount.sh mount " . $_POST["mount"]);
								if(isset($_POST["umount"]))
									shell_exec("/tmp/.http_filesharing/mount.sh umount " . $_POST["umount"]);
								if(isset($_POST["lazyumount"]))
									shell_exec("/tmp/.http_filesharing/mount.sh lazyumount " . $_POST["lazyumount"]);

								echo "<h1>Available devices</h1>";
								echo "<form action=\".?admin\" method=\"post\">";
									echo "<table>";
										echo shell_exec("/tmp/.http_filesharing/mount.sh");
									echo "</table>";
								echo "</form>";
								echo "<br><a href=\"/\" style=\"text-decoration: none;\">Back to the file browser</a><br><br>";

								echo "<form action=\".?admin\" method=\"post\"><button type=\"submit\" name=\"admin-logout\" value=\"admin-logout\">Logout</button></form>";
							}
						}
						else
						{
							// only logged - refresh
							if(isset($_POST["user"]) && isset($_POST["password"]))
							{
								// check login and password
								if($_POST["user"] === $ADMIN_USER && $_POST["password"] === $ADMIN_PASSWORD)
								{
									$_SESSION["admin-logged"]=true;
									//echo "<h1>Loading...</h1>";
									echo "<meta http-equiv=\"refresh\" content=\"0\">";
								}
								else
									echo "<h2>Wrong username or password!</h2><a href=\".?admin\" style=\"text-decoration: none;\">Try again</a>";
							}
							else
							{
								// login
								?>
								<h1>Administration</h1>
								<form action=".?admin" method="post">
									Username: <input type="text" name="user" style="margin-bottom: 1px;"><br>
									Password: <input type="password" name="password"><br>
									<input type="submit" value="Login">
								</form>
								<a href="/" style="text-decoration: none;">Back to the file browser</a>
								<?php
							}
						}
						echo "</div></body></html>"; // because this part ends before html footer send
						exit();
					}
				?>

				<?php
					// file browser

					// if file doesnt exists or access denied
					if($NOT_EXISTS)
						echo "<h2>File does not exist</h2>";
					else
					{
						$filelist=""; // init list

						// correct path for links
						strtok($_SERVER["REQUEST_URI"], "?") === "/" ? $corrected_path="/" : $corrected_path=strtok($_SERVER["REQUEST_URI"], "?")."/";

						// read content and make list
						if($handle=opendir($SHARED_DIRECTORY . rawurldecode(strtok($_SERVER["REQUEST_URI"], "?"))))
							while(($file=readdir($handle)) !== false)
							{
								if(($file != ".") && ($file != ".."))
									is_dir($SHARED_DIRECTORY . $corrected_path . $file) ? $filelist=$filelist . "<li class=\"folder\"><a href=\"" . $corrected_path . rawurlencode($file) . "\">" . $file . "</a>" : $filelist=$filelist . "<li class=\"file\"><a href=\"" . $corrected_path . rawurlencode($file) . "\">" . $file . "</a>";
							}

						// print list
						if($filelist == "")
							echo "<h2>Empty</h2>";
						else
							echo "<ul>" . $filelist . "</ul>";
					}
				?>
			</div>
		</body>
	</html>
' | php_optimize > /tmp/.http_filesharing/router.php
chmod 600 /tmp/.http_filesharing/router.php

# Create php custom configuration
echo '
	[PHP]
	engine = On
	short_open_tag = Off
	precision = 14
	output_buffering = 4096
	zlib.output_compression = Off
	implicit_flush = Off
	unserialize_callback_func =
	serialize_precision = 17
	;disable_functions =
	disable_classes =
	zend.enable_gc = On
	;expose_php = On
	;max_execution_time = 30
	;max_input_time = 60
	;memory_limit = -1
	error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
	;display_errors = Off
	display_startup_errors = Off
	log_errors = On
	log_errors_max_len = 1024
	ignore_repeated_errors = Off
	ignore_repeated_source = Off
	report_memleaks = On
	track_errors = Off
	html_errors = On
	variables_order = "GPCS"
	request_order = "GP"
	register_argc_argv = Off
	auto_globals_jit = On
	;post_max_size = 8M
	auto_prepend_file =
	auto_append_file =
	default_mimetype = "text/html"
	default_charset = "UTF-8"
	doc_root =
	user_dir =
	enable_dl = Off
	;file_uploads = On
	upload_max_filesize = 2M
	max_file_uploads = 20
	;allow_url_fopen = On
	;allow_url_include = Off
	default_socket_timeout = 60

	[CLI Server]
	cli_server.color = On

	[Pdo_mysql]
	pdo_mysql.cache_size = 2000
	pdo_mysql.default_socket=

	[mail function]
	SMTP = localhost
	smtp_port = 25
	mail.add_x_header = On

	[SQL]
	sql.safe_mode = Off

	[ODBC]
	odbc.allow_persistent = On
	odbc.check_persistent = On
	odbc.max_persistent = -1
	odbc.max_links = -1
	odbc.defaultlrl = 4096
	odbc.defaultbinmode = 1

	[Interbase]
	ibase.allow_persistent = 1
	ibase.max_persistent = -1
	ibase.max_links = -1
	ibase.timestampformat = "%Y-%m-%d %H:%M:%S"
	ibase.dateformat = "%Y-%m-%d"
	ibase.timeformat = "%H:%M:%S"

	[MySQLi]
	mysqli.max_persistent = -1
	mysqli.allow_persistent = On
	mysqli.max_links = -1
	mysqli.cache_size = 2000
	mysqli.default_port = 3306
	mysqli.default_socket =
	mysqli.default_host =
	mysqli.default_user =
	mysqli.default_pw =
	mysqli.reconnect = Off

	[mysqlnd]
	mysqlnd.collect_statistics = On
	mysqlnd.collect_memory_statistics = Off

	[PostgreSQL]
	pgsql.allow_persistent = On
	pgsql.auto_reset_persistent = Off
	pgsql.max_persistent = -1
	pgsql.max_links = -1
	pgsql.ignore_notice = 0
	pgsql.log_notice = 0

	[bcmath]
	bcmath.scale = 0

	[Session]
	session.save_handler = files
	session.use_strict_mode = 0
	session.use_cookies = 1
	session.use_only_cookies = 1
	session.name = PHPSESSID
	session.auto_start = 0
	session.cookie_lifetime = 0
	session.cookie_path = /
	session.cookie_domain =
	session.cookie_httponly =
	session.serialize_handler = php
	session.gc_probability = 0
	session.gc_divisor = 1000
	session.gc_maxlifetime = 1440
	session.referer_check =
	session.cache_limiter = nocache
	session.cache_expire = 180
	session.use_trans_sid = 0
	session.hash_function = 0
	session.hash_bits_per_character = 5
	url_rewriter.tags = "a=href,area=href,frame=src,input=src,form=fakeentry"

	[Assertion]
	zend.assertions = -1

	[Tidy]
	tidy.clean_output = Off

	[soap]
	soap.wsdl_cache_enabled=1
	;soap.wsdl_cache_dir="/tmp"
	soap.wsdl_cache_ttl=86400
	soap.wsdl_cache_limit = 5

	[ldap]
	ldap.max_links = -1


	; Paths
	error_log="/tmp/.http_filesharing/error_log"
	upload_tmp_dir="/tmp/.http_filesharing/"
	session.save_path="/tmp/.http_filesharing"
	soap.wsdl_cache_dir="/tmp/.http_filesharing"

	; Security settings

	; Restrict PHP Information Leakage
	expose_php=Off

	; Do not expose PHP error messages
	display_errors=Off

	; Disallow uploading files
	file_uploads=Off

	; Turn off remote code execution
	allow_url_fopen=Off
	allow_url_include=Off

	; POST size
	post_max_size=1K

	; Resource control
	max_execution_time=30
	max_input_time=30
	memory_limit=40M

	; Disable dangerous PHP functions
	disable_functions=exec,passthru,system,proc_open,popen,curl_exec,curl_multi_exec,parse_ini_file,show_source

' > /tmp/.http_filesharing/php.ini

# Mount helper
echo '#!/bin/sh
	if [ "$1" = "mount" ]; then
		[ -e /tmp/usb_drives/${2##*/} ] || mkdir /tmp/usb_drives/${2##*/}
		mount $2 /tmp/usb_drives/${2##*/} || rmdir /tmp/usb_drives/${2##*/}
		exit 0
	fi
	if [ "$1" = "umount" ]; then
		umount /tmp/usb_drives/${2##*/} && rmdir /tmp/usb_drives/${2##*/}
		exit 0
	fi
	if [ "$1" = "lazyumount" ]; then
		umount -l /tmp/usb_drives/${2##*/}
		rmdir /tmp/usb_drives/${2##*/}
		exit 0
	fi

	no_devices=true
	for i in /dev/sd[a-z]; do
		if [ $(cat /sys/block/${i##*/}/removable) = 1 ]; then
			if [ -e ${i}1 ]; then
				echo "<tr><td>$i</td><td></td><td>$(cat /sys/block/${i##*/}/device/vendor | xargs) $(cat /sys/block/${i##*/}/device/model | xargs)</td></tr>" || echo "<tr><td>$i</td><td><button type=\"submit\" name=\"mount\" value=\"${i}\">Mount</button></td><td>$(cat /sys/block/${i##*/}/device/vendor | xargs) $(cat /sys/block/${i##*/}/device/model | xargs)</td></tr>"
				for x in ${i}[0-9]; do
					mountpoint -q /tmp/usb_drives/${x##*/} && echo "<tr><td>$x</td><td><button type=\"submit\" name=\"umount\" value=\"${x}\">Unmount</button></td></tr>" || echo "<tr><td>$x</td><td><button type=\"submit\" name=\"mount\" value=\"${x}\">Mount</button></td></tr>"
					no_devices=false
				done
			else
				mountpoint -q /tmp/usb_drives/${i##*/} && echo "<tr><td>$i</td><td><button type=\"submit\" name=\"umount\" value=\"${i}\">Unmount</button></td><td>$(cat /sys/block/${i##*/}/device/vendor | xargs) $(cat /sys/block/${i##*/}/device/model | xargs)</td></tr>" || echo "<tr><td>$i</td><td><button type=\"submit\" name=\"mount\" value=\"${i}\">Mount</button></td><td>$(cat /sys/block/${i##*/}/device/vendor | xargs) $(cat /sys/block/${i##*/}/device/model | xargs)</td></tr>"
				no_devices=false
			fi
		fi
	done

	for i in /tmp/usb_drives/*; do
		if [ ! -e /dev/${i##*/} ]; then
			mountpoint -q $i && echo "<tr><td>Orphaned /dev/${i##*/}</td><td><button type=\"submit\" name=\"lazyumount\" value=\"${i}\">Remove</button></td></tr>"
		fi
	done

	$no_devices && echo "<h2>No devices available</h2>"

	exit 0
' > /tmp/.http_filesharing/mount.sh
chmod 755 /tmp/.http_filesharing/mount.sh

# Start PHP server
cd /tmp/usb_drives
php -S 0.0.0.0:${1} -c /tmp/.http_filesharing/php.ini /tmp/.http_filesharing/router.php > /tmp/.http_filesharing/php.log 2>&1

exit 0
