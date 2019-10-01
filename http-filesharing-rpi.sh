#!/bin/sh
# Share files via HTTP
# 08.06.2019 - 11.06.2019
# Patch 15.08.2019

# Default filesharing settings
PPATH='/your/default/path' # Path
PPORT=8080 # Port
PLOGIN='yourdefaultlogin' # Login
PSTATS=true # Enable stats
PPASSWORD='yourdefaultpassword' # Password (for stats)
PSHPASSWORD='yourdefaultpassword' # Share password (main)
PPASSPROTECTED=false # Password-protected sharing enabled
PDENIEDDIRS='/Packages /Applications' # Deny access to this directories
PSHAREHIDDEN=true # Don't show hidden files

# PHP settings
php_binary='/usr/local/share/http-filesharing/bin/php7.0'
php_libs='/usr/local/share/http-filesharing/lib'
php_workspace='/tmp/.php'
php_router_location="${php_workspace}/.filesharing.php"
php_configuration="${php_workspace}/.filesharing.ini"
php_router_statscript="${php_workspace}/.filesharing.sh"

# Script settings
enable_iptables_port_open=true

# Simple functions
show_error()
{
	export error='<window title="HTTP file sharing" icon-name="folder-publicshare" resizable="false"><vbox><hbox><pixmap><input file stock="gtk-dialog-error"></input></pixmap><text><label>'"$@"'</label></text></hbox><hbox><button ok></button></hbox></vbox></window>'; gtkdialog --center --program=error
	exit 1
}
show_info()
{
	if [ "$1" = 'stop' ]; then kill $GTKDIALOG_INFO_PID; return 0; fi
	export info='<window decorated="false" skip_taskbar_hint="true" title="HTTP file sharing" resizable="false"><vbox><hbox><pixmap><input file stock="gtk-dialog-info"></input></pixmap><text><label>'"$@"'</label></text></hbox></vbox></window>'; gtkdialog --center --program=info &
	GTKDIALOG_INFO_PID=$!
}
print_S1()
{
	# for php_optimize()
	echo -n "$1"
}
php_optimize()
{
	# This function renames " to ' and remove tabulations (compress file)
	show_info 'Starting...'

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

	show_info 'stop'
}

# Check if php is installed
$php_binary --help > /dev/null 2>&1 || show_error 'PHP not installed'

# Create and run dialog
[ ! "$PDENIEDDIRS" = '' ] && PDENIEDDIRS='<default>'"$PDENIEDDIRS"'</default>'
$PPASSPROTECTED && SSHPASSWORD_SENSITIVE=true || SSHPASSWORD_SENSITIVE=false
export DIALOG='
	<window title="HTTP file sharing" icon-name="folder-publicshare" resizable="false" width-request="780" height-request="390" decorated="true">
		<vbox>
			<hbox space-expand="true" space-fill="true">
				<frame IP: '"$(hostname -I | xargs)"'>
					<hbox>
						<text>
							<label>Path to share:</label>
						</text>
						<entry>
							 <default>'"$PPATH"'</default>
							 <variable>SPATH</variable>
						</entry>
						<text>
							<label>be careful with this</label>
						</text>
					</hbox>
					<hbox>
						<text>
							<label>Port:</label>
						</text>
						<entry>
							 <default>'"$PPORT"'</default>
							 <variable>SPORT</variable>
						</entry>
						<text>
							<label>if selected port 80, you don'"'"'t need :80 in URL</label>
						</text>
					</hbox>
					<hbox>
						<text>
							<label>Login:</label>
						</text>
						<entry>
							 <default>'"$PLOGIN"'</default>
							 <variable>SLOGIN</variable>
						</entry>
						<vseparator></vseparator>
						<checkbox>
							<label>Enable stats page</label>
							<default>'"$PSTATS"'</default>
							<variable>SSTATS</variable>
						</checkbox>
					</hbox>
					<hbox>
						<text>
							<label>Stats password:</label>
						</text>
						<entry>
							 <default>'"$PPASSWORD"'</default>
							 <variable>SPASSWORD</variable>
						</entry>
						<vseparator></vseparator>
						<text>
							<label>File browser password:</label>
						</text>
						<entry sensitive="'"$SSHPASSWORD_SENSITIVE"'">
							 <default>'"$PSHPASSWORD"'</default>
							 <variable>SSHPASSWORD</variable>
						</entry>
						<checkbox>
							<label>Password-protected sharing</label>
							<default>'"$PPASSPROTECTED"'</default>
							<variable>SPASSPROTECTED</variable>
							<action>if true enable:SSHPASSWORD</action>
							<action>if false disable:SSHPASSWORD</action>
						</checkbox>
					</hbox>
					<hbox>
						<text>
							<label>Denied directories:</label>
						</text>
						<entry>
							 '"$PDENIEDDIRS"'
							 <variable>SDENIEDDIRS</variable>
						</entry>
						<vseparator></vseparator>
						<checkbox>
							<label>Don'"'"'t share hidden files</label>
							<default>'"$PSHAREHIDDEN"'</default>
							<variable>SSHAREHIDDEN</variable>
						</checkbox>
					</hbox>
					<hbox homogeneous="true" space-fill="true"><hseparator space-fill="true"></hseparator></hbox>
					<hbox homogeneous="true">
						<text><label>Your share will be available at http://'"$(hostname -I | xargs)"':Port</label></text>
						<text><label>with default settings: http://'"$(hostname -I | xargs)"':'"$PPORT"'</label></text>
					</hbox>
					<hbox homogeneous="true" space-fill="true"><hseparator space-fill="true"></hseparator></hbox>
					<hbox homogeneous="true">
						<text><label>Hints for denying dirs:</label></text>
						<text><label>always start with /</label></text>
						<text><label>if you need space, write %20</label></text>
					</hbox>
					<hbox homogeneous="true">
						<text><label>Usage: /dir1 /dirB</label></text>
						<text><label>"/dir%20with%20spaces"</label></text>
						<text><label>"/dir%20C/subdir"</label></text>
					</hbox>
				</frame>
			</hbox>
			<hbox homogeneous="true" space-expand="false" space-fill="false">
				<button image-position="2" theme-icon-size="30" space-fill="true">
					<label>OK</label>
					<input file icon="gtk-ok"></input>
				</button>
				<button image-position="2" theme-icon-size="30" space-fill="true">
					<label>Cancel</label>
					<input file icon="gtk-cancel"></input>
				</button>
			</hbox>
		</vbox>
	</window>
'
eval $(gtkdialog --center --program=DIALOG)
[ "$EXIT" = 'Cancel' ] && exit 0
[ "$EXIT" = 'abort' ] && exit 0

# Check if share path exists
[ -e $SPATH ] || show_error "$SPATH doesn't exists"

# Check if php need root
[ $SPORT -le 1024 ] && sudo='sudo' || sudo=''

# Check if need open port
if $enable_iptables_port_open; then
	if sudo iptables -L -n | grep "dpt:${SPORT}"'$' | grep 'ACCEPT' > /dev/null 2>&1; then
		iptables__end_action='none'
	else
		sudo iptables -A INPUT -p TCP --dport $SPORT -j ACCEPT
		iptables__end_action='remove'
	fi	
fi

# Prepare some variables
if [ "$SDENIEDDIRS" = '' ]; then
	NSDENIEDDIRS='"emptynone"'
else
	for i in $SDENIEDDIRS; do
		NSDENIEDDIRS="${NSDENIEDDIRS}""'""${i}""',"
	done
	NSDENIEDDIRS=${NSDENIEDDIRS%,}
fi

# Create php workspace
if [ ! -e /tmp/.php ]; then
	mkdir /tmp/.php || show_error 'Cant'"'"'t create PHP workspace'
fi

# Create PHP script and optimize it
echo -n '
	<?php
		// All of the following settings will be set by shell script

		// start session only for stats
		if(isset($_GET["stats"]))
			session_start();

		// set shared directory
		$SHARED_DIRECTORY="'"$SPATH"'"; // set

		// set password to file browser - login is the same as for stats
		$BROWSER_PROTECTED='"$SPASSPROTECTED"'; // set
		$BROWSER_PASSWORD="'"$SSHPASSWORD"'"; // set
		if($BROWSER_PROTECTED && session_status() === PHP_SESSION_NONE)
			session_start();

		// set login and password to stats
		$STATS_ENABLED='"$SSTATS"'; // set
		$STATS_USER="'"$SLOGIN"'"; // set
		$STATS_PASSWORD="'"$SPASSWORD"'"; // set

		// little, but essential flag
		$NOT_EXISTS=false;

		// do not process jump to php/html && regular file if file browser is protected and user not logged
		if($BROWSER_PROTECTED && !(isset($_SESSION["browser-logged"]) && $_SESSION["browser-logged"]))
			$NOT_EXISTS=true;

		// set deny list and function
		$DENIED_DIRS=array('"$NSDENIEDDIRS"'); // set
		$check_denied_dir=function($string)
		{
			global $DENIED_DIRS;
			foreach ($DENIED_DIRS as $value)
			{
				if($value === substr($string, 0, strlen($value)))
					return true;
			}
			return false;
		};
		$check_denied_dir(strtok($_SERVER["REQUEST_URI"], "?")) ? $NOT_EXISTS=true : false;

		// check if file exists
		!file_exists(rawurldecode(strtok($_SERVER["DOCUMENT_ROOT"] . $_SERVER["REQUEST_URI"], "?"))) ? $NOT_EXISTS=true : false;

		// if file hidden, deny
		$DENY_HIDDEN_FILES='"$SSHAREHIDDEN"'; // set
		if($DENY_HIDDEN_FILES && strtok($_SERVER["REQUEST_URI"], "?") != "/" && basename(strtok($_SERVER["REQUEST_URI"], "?"))[0] === ".")
			$NOT_EXISTS=true;

		// do not process this if $NOT_EXISTS is true
		if(!$NOT_EXISTS)
		{
			// check if directory has index.php or index.html
			if(file_exists($SHARED_DIRECTORY . rawurldecode(strtok($_SERVER["REQUEST_URI"], "?")) . "/index.html") || file_exists($SHARED_DIRECTORY . rawurldecode(strtok($_SERVER["REQUEST_URI"], "?")) . "/index.php"))
			{
				// clean variables before executing script
				unset($SHARED_DIRECTORY);
				unset($BROWSER_PROTECTED);
				unset($BROWSER_PASSWORD);
				unset($STATS_ENABLED);
				unset($STATS_USER);
				unset($STATS_PASSWORD);
				unset($NOT_EXISTS);
				unset($DENIED_DIRS);
				unset($check_denied_dir);
				unset($DENY_HIDDEN_FILES);

				// abort this script
				return false;
			}

			// if url is regular file, abort this script
			if(!is_dir($SHARED_DIRECTORY . rawurldecode(strtok($_SERVER["REQUEST_URI"], "?"))))
				return false;
		}
	?>
	<!DOCTYPE html>
	<html>
		<head>
			<title>Multimedia Box</title>
			<meta charset="utf-8">
			<link rel="shortcut icon" href="data:image/x-icon;base64,AAABAAEAEBAAAAEAIABoBAAAFgAAACgAAAAQAAAAIAAAAAEAIAAAAAAAAAQAABMLAAATCwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANAAAAAA8NBCx8HghZ4x4IWOMNBCt6AAAADAAACwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAMBDkQCAQ23IAld+D4QsP8+ELH/Iglj9wMBD64DAQ4+AAAABQAAAAAAAAAAAAAAAAAAAAAAAAcAAAAAAg4ELHQoC3TvJwtz/wsDJf8dCFf/Hwlb/w4ELv8pC3f/KAt17w8EL3kAAAAEAAAHAAAAAAAAAAAAAgEMAAAAAiolCm3kRBHA/zMNkv8eCFn/PBCr/zwQrP8jCmf/Nw6d/0MRwP8nCnHoAAAHLgIBDwAAAAAAAAAGAAMBEAABAQlmKgt5/jsQqf8VBj7/LQyA/0QRwf9EEcH/Mg2P/x0IVv9AEbf/LgyF/AMBDVcEARIAAAAKAAAACQAAAAAQFgZDvhkHSv8OBCz/DwQw/yAJXv85D6P/Ow+n/yIJY/8OBC3/FwZG/yEJX/8SBTmmAAAABwAACQACAQ0AAAAHMywMgO8nCnH/Hwhc/z8RtP85D6L/GAdI/xQGPv80Dpb/PhCw/x4IWP8qC3j/KAtz4wAAACMAAAkAAQALAAAAACMlCmveLAx9/y8Mhv9DEcD/RBHA/ygLcv8jCWb/QxG//0QRwP8wDYj/MQ2K/yIJY9QAAAAZAAAJAAAACAAAAAABDAQobBEFNvgbB1L/PxCz/0IRvP8hCV//IAld/0MRvf9AEbX/HghY/xYGQvMMAydipi//AAAACAAAAAAAAAAFAAAAABkdCFXXJwpw/xkHSv8gCV7/HghX/yAJX/8lCmv/HghY/ysMfP8ZB0nCAAAADAAABAAAAAAAAAAAAAAACQAAAAACEgU3hjELjfslCGr/Hwhc/0IRuv9CEbv/JAlp/yoJeP8uCoP3DQMsbEIRuAAAAAkAAAAAAAAAAAAAAAAAAwsOAAEEBjcQKTHiHUtW/xAiM/8bBlD/GwZQ/xAeM/8dS1b/Dy4w3gEHCDcEExQAAAAAAAAAAAAAAAAAAQQKAAAAABcRQjO8I5Vn/yirdP8bclH/BBIS/wMOEP8ZaUv/KKp0/ySZav8SSDjIAAAFHwIGDAAAAAAAAAAJAAwqJAAHGBlhH39a/CiodP8jjmT/Ioti/xdfRv4VV0H9Ioxj/yKMYv8op3P/IYZf/wkfHXEUSDgAAAAJAAAACQAli2MACSQgjCCGX/8mnm7/Jp1u/ySYav8UTzzFEkc3vSSWaf8mnm7/Jp1u/yKMYv8LKiSdAAAAAAAACQAAAAkACiQgAAQNET8NMyqtE0o54hRNO+YONSuzBRETNgQOEC0NMimsE0w65BNLOuQONSyzBA8TSBZTPwAAAAkA+B8AAOAHAADAAwAAwAMAAMADAACAAQAAgAEAAIABAACAAwAAwAMAAMAHAADgBwAAwAMAAMADAADAAQAAwAMAAA==" type="image/x-icon">
			<link rel="icon" href="data:image/x-icon;base64,AAABAAEAEBAAAAEAIABoBAAAFgAAACgAAAAQAAAAIAAAAAEAIAAAAAAAAAQAABMLAAATCwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANAAAAAA8NBCx8HghZ4x4IWOMNBCt6AAAADAAACwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAMBDkQCAQ23IAld+D4QsP8+ELH/Iglj9wMBD64DAQ4+AAAABQAAAAAAAAAAAAAAAAAAAAAAAAcAAAAAAg4ELHQoC3TvJwtz/wsDJf8dCFf/Hwlb/w4ELv8pC3f/KAt17w8EL3kAAAAEAAAHAAAAAAAAAAAAAgEMAAAAAiolCm3kRBHA/zMNkv8eCFn/PBCr/zwQrP8jCmf/Nw6d/0MRwP8nCnHoAAAHLgIBDwAAAAAAAAAGAAMBEAABAQlmKgt5/jsQqf8VBj7/LQyA/0QRwf9EEcH/Mg2P/x0IVv9AEbf/LgyF/AMBDVcEARIAAAAKAAAACQAAAAAQFgZDvhkHSv8OBCz/DwQw/yAJXv85D6P/Ow+n/yIJY/8OBC3/FwZG/yEJX/8SBTmmAAAABwAACQACAQ0AAAAHMywMgO8nCnH/Hwhc/z8RtP85D6L/GAdI/xQGPv80Dpb/PhCw/x4IWP8qC3j/KAtz4wAAACMAAAkAAQALAAAAACMlCmveLAx9/y8Mhv9DEcD/RBHA/ygLcv8jCWb/QxG//0QRwP8wDYj/MQ2K/yIJY9QAAAAZAAAJAAAACAAAAAABDAQobBEFNvgbB1L/PxCz/0IRvP8hCV//IAld/0MRvf9AEbX/HghY/xYGQvMMAydipi//AAAACAAAAAAAAAAFAAAAABkdCFXXJwpw/xkHSv8gCV7/HghX/yAJX/8lCmv/HghY/ysMfP8ZB0nCAAAADAAABAAAAAAAAAAAAAAACQAAAAACEgU3hjELjfslCGr/Hwhc/0IRuv9CEbv/JAlp/yoJeP8uCoP3DQMsbEIRuAAAAAkAAAAAAAAAAAAAAAAAAwsOAAEEBjcQKTHiHUtW/xAiM/8bBlD/GwZQ/xAeM/8dS1b/Dy4w3gEHCDcEExQAAAAAAAAAAAAAAAAAAQQKAAAAABcRQjO8I5Vn/yirdP8bclH/BBIS/wMOEP8ZaUv/KKp0/ySZav8SSDjIAAAFHwIGDAAAAAAAAAAJAAwqJAAHGBlhH39a/CiodP8jjmT/Ioti/xdfRv4VV0H9Ioxj/yKMYv8op3P/IYZf/wkfHXEUSDgAAAAJAAAACQAli2MACSQgjCCGX/8mnm7/Jp1u/ySYav8UTzzFEkc3vSSWaf8mnm7/Jp1u/yKMYv8LKiSdAAAAAAAACQAAAAkACiQgAAQNET8NMyqtE0o54hRNO+YONSuzBRETNgQOEC0NMimsE0w65BNLOuQONSyzBA8TSBZTPwAAAAkA+B8AAOAHAADAAwAAwAMAAMADAACAAQAAgAEAAIABAACAAwAAwAMAAMAHAADgBwAAwAMAAMADAADAAQAAwAMAAA==" type="image/x-icon">
			<style type="text/css">
				table, tr, td {
					border: none;
				}
				table {
					margin-left: auto;
					margin-right: auto;
				}
				#header-text {
					text-align: center;
					font-weight: bold;
					font-size: 18pt;
					text-decoration: none;
					color: #000000;
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
				<table>
					<tr>
						<td>
							<img src="data:image/png;base64,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" alt="logo">
						</td>
						<td>
							<?php
								if($STATS_ENABLED)
									echo "<a id=\"header-text\" href=\"/?stats\">Raspberry Pi Multimedia box</a>";
								else
									echo "<span id=\"header-text\">Raspberry Pi Multimedia box</span>";
							?>
						</td>
					</tr>
				</table>
				<hr>
			</div>
			<div>
				<?php
					// stats
					if(isset($_GET["stats"]))
					{
						// check if enabled
						if(!$STATS_ENABLED)
						{
							echo "<h2>Stats disabled</h2><a href=\"/\" style=\"text-decoration: none;\">Back to the file browser</a></div></body></html>";
							exit();
						}

						// logout
						if(isset($_POST["stats-logout"]))
						{
							$_SESSION["stats-logged"]=false;
							session_destroy();
							echo "<meta http-equiv=\"refresh\" content=\"0\"></div></body></html>";
							exit();
						}

						// logged and displayed
						if(isset($_SESSION["stats-logged"]))
						{
							if($_SESSION["stats-logged"])
							{	
								echo "<pre>";

								// system info
								echo shell_exec("/tmp/.php/.filesharing.sh");
								// php info
								if(extension_loaded("fileinfo") && extension_loaded("ftp") && extension_loaded("PDO") && extension_loaded("posix"))
									echo "PHP v" . phpversion() . " installation: full";
								else
									echo "PHP v" . phpversion() . " installation: lite";

								// sqlite3 check
								if(extension_loaded("sqlite3") && extension_loaded("pdo_sqlite"))
									echo " with SQLite3 v" . phpversion("sqlite3") . "\n";

								echo "\n";
								echo "</pre>";
								echo "<form action=\".?stats\" method=\"post\"><button type=\"submit\" name=\"stats-logout\" value=\"stats-logout\">Logout</button></form>";
							}
						}
						else
						{
							// only logged - refresh
							if(isset($_POST["user"]) && isset($_POST["password"]))
							{
								// check login and password
								if($_POST["user"] === $STATS_USER && $_POST["password"] === $STATS_PASSWORD)
								{
									$_SESSION["stats-logged"]=true;
									//echo "<h1>Loading...</h1>";
									echo "<meta http-equiv=\"refresh\" content=\"0\">";
								}
								else
									echo "<h2>Wrong username or password!</h2><a href=\".?stats\" style=\"text-decoration: none;\">Try again</a>";
							}
							else
							{
								// login
								?>
								<h1>Sysinfo panel</h1>
								<form action=".?stats" method="post">
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

					// check if share is protected
					if($BROWSER_PROTECTED)
					{
						// logout
						if(isset($_POST["browser-logout"]))
						{
							$_SESSION["browser-logged"]=false;
							session_destroy(); // also logout from stats
							echo "<meta http-equiv=\"refresh\" content=\"0\"></div></body></html>";
							exit();
						}

						// logged and displayed
						if(isset($_SESSION["browser-logged"]))
						{
							// display only the button and jump down to the file list
							if($_SESSION["browser-logged"])
								echo "<form action=\"/\" method=\"post\"><button type=\"submit\" name=\"browser-logout\" value=\"browser-logout\">Logout</button></form><hr>";
						}
						else
						{
							// only logged - refresh
							if(isset($_POST["user"]) && isset($_POST["password"]))
							{
								// check login and password
								if($_POST["user"] === $STATS_USER && $_POST["password"] === $BROWSER_PASSWORD)
								{
									$_SESSION["browser-logged"]=true;
									//echo "<h1>Loading...</h1>";
									echo "<meta http-equiv=\"refresh\" content=\"0\"></div></body></html>";
									exit();
								}
								else
								{
									echo "<h2>Wrong username or password!</h2><a href=\".\" style=\"text-decoration: none;\">Try again</a></div></body></html>";
									exit();
								}
							}
							else
							{
								// login
								?>
								<h1>File browser</h1>
								<form action="." method="post">
									Username: <input type="text" name="user" style="margin-bottom: 1px;"><br>
									Password: <input type="password" name="password"><br>
									<input type="submit" value="Login">
								</form>
								</div></body></html>
								<?php
								exit();
							}
						}
					}

					// if file doesnt exists or access denied
					if($NOT_EXISTS)
						echo "<h2>File does not exist</h2>";
					else
					{
						$filelist=""; // init list

						// correct path for links (B for is_dir(), A for everyting else)
						strtok($_SERVER["REQUEST_URI"], "?") === "/" ? $corrected_path_A="" : $corrected_path_A=strtok($_SERVER["REQUEST_URI"], "?")."/";
						strtok($_SERVER["REQUEST_URI"], "?") === "/" ? $corrected_path_B="/" : $corrected_path_B=rawurldecode(strtok($_SERVER["REQUEST_URI"], "?"))."/";

						// read content and make list
						if($handle=opendir($SHARED_DIRECTORY . rawurldecode(strtok($_SERVER["REQUEST_URI"], "?"))))
							while(($file=readdir($handle)) !== false)
							{
								// check if show hidden files
								if($DENY_HIDDEN_FILES)
								{
									if(($file != ".") && ($file != "..") && ($file[0] != ".") && !$check_denied_dir($corrected_path_A . "/" . $file))
										is_dir($SHARED_DIRECTORY . $corrected_path_B . $file) ? $filelist=$filelist . "<li class=\"folder\"><a href=\"" . $corrected_path_A . rawurlencode($file) . "\">" . $file . "</a>" : $filelist=$filelist . "<li class=\"file\"><a href=\"" . $corrected_path_A . rawurlencode($file) . "\">" . $file . "</a>";
								}
								else
								{
									if(($file != ".") && ($file != "..") && !$check_denied_dir($corrected_path_A . "/" . $file))
										is_dir($SHARED_DIRECTORY . $corrected_path_B . $file) ? $filelist=$filelist . "<li class=\"folder\"><a href=\"" . $corrected_path_A . rawurlencode($file) . "\">" . $file . "</a>" : $filelist=$filelist . "<li class=\"file\"><a href=\"" . $corrected_path_A . rawurlencode($file) . "\">" . $file . "</a>";
								}
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
' | php_optimize > $php_router_location || show_error 'Can'"'"'t write configured script'

# Create stats backend
echo '#!/bin/bash' > $php_router_statscript
echo '
	[ -e '"$HOME"'/.bash_login ] && . '"$HOME"'/.bash_login | sed -e "1,12d" || echo "System stats not available"
	exit 0
' | sed -e 's/"/'"'"'/g' >> $php_router_statscript
chmod 755 $php_router_statscript

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
	error_log="'"$php_workspace"'/error_log"
	upload_tmp_dir="'"$php_workspace"'/"
	session.save_path="'"$php_workspace"'"
	soap.wsdl_cache_dir="'"$php_workspace"'"

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
' > $php_configuration

# Start PHP server
export LD_LIBRARY_PATH=$php_libs
lxterminal --title="HTTP file sharing" -e ${sudo} ${php_binary} -c ${php_configuration} -t ${SPATH} -S 0.0.0.0:${SPORT} $php_router_location

# Wait for end
sleep 5
while ps -A | grep ${php_binary##*/} > /dev/null 2>&1; do
	sleep 2
done

# After closing the terminal, set iptables
[ "$iptables__end_action" = 'remove' ] && sudo iptables -D INPUT -p TCP --dport $SPORT -j ACCEPT

exit 0
