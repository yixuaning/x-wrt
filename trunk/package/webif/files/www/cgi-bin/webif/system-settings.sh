#!/usr/bin/webif-page
<?
. "/usr/lib/webif/webif.sh"

###################################################################
# system configuration page
#
# Description:
#	Configures general system settings.
#
# Author(s) [in order of work date]:
#   	Original webif developers -- todo
#	Markus Wigge <markus@freewrt.org>
#   	Jeremy Collake <jeremy.collake@gmail.com>
#	Travis Kemen <kemen04@gmail.com>
#
# Major revisions:
#
# NVRAM variables referenced:
#	time_zone
#  	ntp_server
#
# Configuration files referenced:
#   none
#

###### This nightmare's author is lubek
###### This is the ugly hack to get the old value of 
###### a config variable and set its value only once.
###### It is currently used only for the language setting.
###### Try setting the different language several times and save
###### changes, repeat the same with themes to see what is wrong!
###### These functions should be offered by the UCI!
###### Remove this hack after the proper implementation in UCI!
. /lib/config/uci.sh
. /lib/config/uci-depends.sh
uci_get_original_value() {
	local PACKAGE="$1"
	local CONFIG="$2"
	local OPTION="$3"
	local VALUE=

	VALUE=$(
		config_load "$PACKAGE" 2>/dev/null
		eval "CONFORIG=\$CONFIG_${CONFIG}_${OPTION}" 2>/dev/null
		echo "$CONFORIG"
	)
	eval "CONFORIG_${CONFIG}_${OPTION}=$VALUE" 2>/dev/null
}
uci_set_replace_value() {
	local OLDVALUE
	uci_get_original_value "$1" "$2" "$3"
	#remove every section with the lang setting
	! equal "$(grep -q "^option[ \t'\"]*$3[ \t'\"]*" "/tmp/.uci/$1" 2>/dev/null)" "0" && {
		awk 'ORS=NR%2?"|":"\n"' "/tmp/.uci/$1" 2>/dev/null |
			sed "s/^CONFIG_SECTION=['\''\"]$2\>.*|option[ \t'\''\"]*$3[ '\''\"]*.*\$//" |
			awk -F "|" ' { if (length($1)>0) print$1"\n"$2 } ' > "/tmp/.uci/$1.new"
		mv -f "/tmp/.uci/$1.new" "/tmp/.uci/$1" 2>/dev/null
		[ -s "/tmp/.uci/$1" ] || rm -f "/tmp/.uci/$1" 2>/dev/null
	}
	eval "OLDVALUE=\$CONFORIG_${2}_${3}"
	! equal "$OLDVALUE" "$4" && uci_set "$1" "$2" "$3" "$4"
}
###### This is the ugly hack

is_bcm947xx && {
	load_settings "system"
	load_settings "webif"
}

uci_load "webif"

is_kamikaze && {
	uci_load "system"
	uci_load "network"
	SSL="field|@TR<<Webif SSL>>
select|ssl_enable|$CONFIG_ssl_enable
option|0|@TR<<Off>>
option|1|@TR<<On>>"
if [ -n "$(has_pkgs matrixtunnel)" ]; then
	STUNNEL_INSTALL_FORM="string|<div class=\"warning\">MatrixTunnel package is not installed. For ssl support you need to install MatrixTunnel:</div>
		submit|install_stunnel| @TR<<Install MatrixTunnel>> |"
fi
}

#####################################################################
# defaults
#
# Overclocking note:
#  we only handle 3302 0.8 since these are usually safer if they have
#  the same default CFE as found on Linksys WRT54G(S) v4+, as it
#  will handle invalid clock frequencies more gracefully and default
#  to a limit of 250mhz. It also has a fixed divider, so sbclock
#  frequencies are implied, and ignored if specified.
#
OVERCLOCKING_DISABLED="1" # set to 1 to disble OC support, we disable overclocking by default for kamikaze and only enable it for bcm947xx
is_bcm947xx && {
	OVERCLOCKING_DISABLED="0"
}

#####################################################################
header "System" "Settings" "@TR<<System Settings>>" ' onload="modechange()" ' "$SCRIPT_NAME"

#####################################################################
# todo: CPU_MODEL not actually used atm (except in building version)
equal "$OVERCLOCKING_DISABLED" "0" && {
	CPU_MODEL=$(sed -n "/cpu model/p" "/proc/cpuinfo")
	CPU_VERSION=$(echo "$CPU_MODEL" | sed -e "s/BCM3302//" -e "s/cpu model//" -e "s/://")
	#echo "debug.model: $CPU_MODEL <br />"
	#echo "debug.version: $CPU_VERSION <br />"
}

#####################################################################
# install NTP client if asked
if ! empty "$FORM_install_ntpclient"; then
	tmpfile=$(mktemp "/tmp/.webif_ntp-XXXXXX")
	echo "Installing NTPCLIENT package ...<pre>"
	install_package "ntpclient"
	echo "</pre>"
fi

if ! empty "$FORM_install_stunnel"; then
	echo "Installing MatrixTunnel package ...<pre>"
	install_package "matrixtunnel"
	if [ ! -e "/etc/matrixtunnel/matrixtunnel.key" ]; then
		ipkg -d ram install "openssl-util"
		ln -s ~/usr/lib/libssl.so.0.9.8 /lib/libssl.so.0.9.8
		ln -s ~/usr/lib/libcrypto.so.0.9.8 /lib/libcrypto.so.0.9.8
		rdate -s pool.ntp.org; /tmp/usr/bin/openssl genrsa -out /etc/ssl/matrixtunnel.key 2048; /tmp/usr/bin/openssl req -new -batch -nodes -key /etc/ssl/matrixtunnel.key -out /etc/ssl/matrixtunnel.csr; /tmp/usr/bin/openssl x509 -req -days 365 -in /etc/ssl/matrixtunnel.csr -signkey /etc/ssl/matrixtunnel.key -out /etc/ssl/matrixtunnel.cert
		ipkg install matrixtunnel
		rm /lib/libcrypto.so.0.9.8
		rm /lib/libssl.so.0.9.8
		ipkg remove openssl-util libopenssl zlib
	fi
	echo "</pre>"
fi

#####################################################################
# initialize forms
if empty "$FORM_submit"; then
	# initialize all defaults
	! is_kamikaze && {	
	FORM_hostname="${wan_hostname:-$(nvram get wan_hostname)}"
	FORM_hostname="${FORM_hostname:-OpenWrt}"
	FORM_system_timezone="${FORM_system_timezone:-$(nvram get time_zone)}"
	FORM_system_timezone="${FORM_system_timezone:-""}"
	FORM_ntp_server="${ntp_server:-$(nvram get ntp_server)}"
	}
	
	is_kamikaze && {
	FORM_hostname="$CONFIG_system_hostname"
	FORM_hostname="${FORM_hostname:-OpenWrt}"
	#wait for ntpclient to be updated
	#FORM_system_timezone="${FORM_system_timezone:-$(nvram get time_zone)}"
	#FORM_system_timezone="${FORM_system_timezone:-""}"
	#FORM_ntp_server="${ntp_server:-$(nvram get ntp_server)}"
	}
	is_bcm947xx && {
		FORM_boot_wait="${boot_wait:-$(nvram get boot_wait)}"
		FORM_boot_wait="${FORM_boot_wait:-off}"
		FORM_wait_time="${wait_time:-$(nvram get wait_time)}"
		FORM_wait_time="${FORM_wait_time:-1}"
		FORM_clkfreq="${clkfreq:-$(nvram get clkfreq)}";
		FORM_clkfreq="${FORM_clkfreq:-200}"
	}
	# webif settings
	uci_load "webif"
	is_kamikaze && {	
		FORM_effect="${CONFIG_general_use_progressbar}"		# -- effects checkbox
		if equal $FORM_effect "1" ; then FORM_effect="checked" ; fi	# -- effects checkbox
	}
	FORM_language="${CONFIG_general_lang:-default}"	
	FORM_theme=${CONFIG_theme_id:-xwrt}
else
#####################################################################
# save forms
	SAVED=1
	validate <<EOF
hostname|FORM_hostname|Hostname|nodots required|$FORM_hostname
EOF
	if equal "$?" 0 ; then
		is_kamikaze && {
		#to check if we actually changed hostname, else donot reload network for no reason!
		uci_load "network"
		if ! equal "$FORM_hostname" "$CONFIG_system_hostname" ; then uci_set "system" "system" "hostname" "$FORM_hostname" ; fi

		uci_set "webif" "ssl" "enable" "$FORM_ssl_enable"
		#waiting for ntpclient update
		#save_setting system time_zone "$FORM_system_timezone"
		#save_setting system ntp_server "$FORM_ntp_server"
		}
		! is_kamikaze && {
			save_setting system wan_hostname "$FORM_hostname"
			save_setting system time_zone "$FORM_system_timezone"
			save_setting system ntp_server "$FORM_ntp_server"
		}
		is_bcm947xx && {
			case "$FORM_boot_wait" in
				on|off) save_setting system boot_wait "$FORM_boot_wait";;
			esac
			! empty "$FORM_wait_time" &&
			{
				save_setting system wait_time "$FORM_wait_time"
			}
			equal "$OVERCLOCKING_DISABLED" "0" && ! empty "$FORM_clkfreq" &&
			{
				save_setting nvram clkfreq "$FORM_clkfreq"
			}
		}
		# webif settings
		! equal "$FORM_theme" "$CONFIG_theme_id" && ! empty "$CONFIG_theme_id" && {	
			uci_set "webif" "theme" "id" "$FORM_theme"
		}
		uci_set_replace_value "webif" "general" "lang" "$FORM_language"
		is_kamikaze && {	
			uci_set "webif" "general" "use_progressbar" "$FORM_effect_enable"
			FORM_effect=$FORM_effect_enable ; if equal $FORM_effect "1" ; then FORM_effect="checked" ; fi
		}
	else
		echo "<br /><div class=\"warning\">Warning: Hostname failed validation. Can not be saved.</div><br />"
	fi
fi

is_kamikaze && {	
	effect_field=$(cat <<EOF
field| 
string|<input type="checkbox" name="effect_enable" value="1" $FORM_effect />&nbsp;@TR<<Enable visual effects>><br/><br/>"
EOF
)
}

#####################################################################
# over/underclocking
#
is_bcm947xx && {
	equal "$OVERCLOCKING_DISABLED" "0" &&
	{
	if [ "$CPU_VERSION" = "V0.8" ]; then
		FORM_clkfreqs="$FORM_clkfreq
			option|184
			option|188
			option|197
			option|200
			option|207
			option|216
			option|217
			option|225
			option|234
			option|238
			option|240
			option|250"
		# special case for custom CFEs (like mine)
		if [ $(nvram get clkfreq) -gt 250 ]; then
			FORM_clkfreqs="$FORM_clkfreqs
				option|$(nvram get clkfreq)"
		fi
	else
		# BCM3302 v0.7 or other..
		# in this case, we'll show it, but not have any options
		FORM_clkfreqs="$FORM_clkfreq
			option|$FORM_clkfreq"
	fi
	}

	#####################################################################
	# Initialize wait_time form
	for wtime in $(seq 1 30); do
		FORM_wait_time="$FORM_wait_time
			option|$wtime"
	done
}

#####################################################################
# Initialize THEMES form
#
#
# start with list of available installable theme packages
#
! exists "/etc/themes.lst" && {
	# create list if it doesn't exist ..
	/usr/lib/webif/webif-mkthemelist.sh	
}
THEMES=$(cat "/etc/themes.lst")
for str in $temp_t; do
	THEME="$THEME
		option|$str"
done

# enumerate installed themes by finding all subdirectories of /www/theme
# this lets users install themes not built into packages.
#
for curtheme in /www/themes/*; do
	curtheme=$(echo "$curtheme" | sed s/'\/www\/themes\/'//g)
	if exists "/www/themes/$curtheme/name"; then
		theme_name=$(cat "/www/themes/$curtheme/name")
	else
		theme_name="$curtheme"
	fi
	! equal "$curtheme" "active" && {
		THEMES="$THEMES
option|$curtheme|$theme_name"
	}
done
#
# sort list and remove dupes
#
THEMES=$(echo "$THEMES" | sort -u)

dangerous_form_start=""
dangerous_form_end=""
dangerous_form_help=""

#####################################################################
# Initialize LANGUAGES form
# create list if it doesn't exist ..
! exists "/etc/languages.lst" && {
	/usr/lib/webif/webif-mklanglist.sh
}
LANGUAGES=$(cat "/etc/languages.lst")

is_bcm947xx && {
	bootwait_form="field|@TR<<Boot Wait>>
	select|boot_wait|$FORM_boot_wait
	option|on|@TR<<Enabled>>
	option|off|@TR<<Disabled>>
	helpitem|Boot Wait
	helptext|HelpText boot_wait#Boot wait causes the boot loader of some devices to wait a few seconds at bootup for a TFTP transfer of a new firmware image. This is a security risk to be left on."

	waittime_form="field|@TR<<Wait Time>>
	select|wait_time|$FORM_wait_time
	helpitem|Wait Time
	helptext|HelpText wait_time#Number of seconds the boot loader should wait for a TFTP transfer if Boot Wait is on."

	equal "$OVERCLOCKING_DISABLED" "0" &&
	{
		clkfreq_form="field|@TR<<CPU Clock Frequency>>
		select|clkfreq|$FORM_clkfreqs"
		dangerous_form_start="start_form|@TR<<Dangerous Settings>>"
		dangerous_form_end="end_form"
		dangerous_form_help="helpitem|CPU Clock Frequency
					helptext|HelpText CPU Clock Frequency#Do not change this. You may brick your router if you do not know what you are doing. We've tried to disable it for all routers that can be bricked through an invalid clock frequency setting. Only Linksys WRT54G v4 units are known to be unbrickable by a bad clkfreq setting."
	}
}

#####################################################################
# check if ntpclient or opennptd is installed and give user option to install ntpclient if neither are installed.
if [ -n "$(has_pkgs ntpclient)" -a -n "$(has_pkgs openntpd)" ]; then
	NTPCLIENT_INSTALL_FORM="string|<div class=\"warning\">No NTP client is installed. For correct time support you need to install one:</div>
		submit|install_ntpclient| Install NTP Client |"
fi

#####################################################################
# initialize time zones

TIMEZONE_OPTS=$(
	awk '
		BEGIN {
			FS="	"
			last_group=""
		}
		/^(#.*)?$/ {next}
		$1 != last_group {
			last_group=$1
			print "optgroup|" $1
		}
		{
			print "option|" $3 "|" $2
		}' < /usr/lib/webif/timezones.csv

)
#######################################################
cat <<EOF
<script type="text/javascript" src="/webif.js"></script>
<script type="text/javascript">
function modechange()
{
	if(isset('boot_wait','on'))
	{
		document.getElementById('wait_time').disabled = false;
	}
	else
	{
		document.getElementById('wait_time').disabled = true;
	}
}
</script>
EOF
#######################################################
# Show form
display_form <<EOF
onchange|modechange
start_form|@TR<<System Settings>>
field|@TR<<Host Name>>
text|hostname|$FORM_hostname
$bootwait_form
$waittime_form
end_form
start_form|@TR<<Time Settings>>
field|@TR<<Timezone>>
select|system_timezone|$FORM_system_timezone
$TIMEZONE_OPTS
field|@TR<<NTP Server>>
text|ntp_server|$FORM_ntp_server
end_form
$NTPCLIENT_INSTALL_FORM
##########################
# webif settings
start_form|@TR<<Webif Settings>>
$effect_field
field|@TR<<Language>>
select|language|$FORM_language
$LANGUAGES
field|@TR<<Theme>>
select|theme|$FORM_theme
$THEMES
$SSL
end_form
$STUNNEL_INSTALL_FORM
# end webif settings
###########################
$dangerous_form_start
$clkfreq_form
$dangerous_form_help
$dangerous_form_end
EOF

footer ?>

<!--
##WEBIF:name:System:10:Settings
-->
