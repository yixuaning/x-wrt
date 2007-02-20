#!/bin/sh
#########################################
# Applications Common Functions
#
# Author(s) [in order of work date]:
#        Dmytro Dykhman <dmytro@iroot.ca>
#

tipcount=1
location=""

HEADER="HTTP/1.0 200 OK
Content-type: text/html

"

HTMLHEAD="<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">

<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"en\" xml:lang=\"en\"><head><title></title>
<link rel='stylesheet' type='text/css' href='/themes/active/webif.css' />
<script type='text/javascript' src='/js/balloontip.js'></script>
<script type="text/javascript" src="/js/window.js"></script>
<script type='text/javascript' src='/js/imgdepth.js'></script>"

TIP() { 
if [ $1 != 0 ]; then
style="style='width: $1px;'"
fi
echo "<div id=\"b$tipcount\" class=\"balloonstyle\" $style>$2</div>"
let "tipcount+=1" 
}

Load_remote_libs()
{
	uci_load "app.ipkg"
	loc="$CONFIG_int_location"

	echo "#!/bin/sh" > /tmp/.D43S.tmp
	echo "START=98" > /tmp/.D43S.tmp
	echo "ls -l $loc/usr/lib/ | awk '{print \" if [ ! -f /usr/lib/\"\$9\" ] \\n then \\n ln -s $loc/usr/lib/\"\$9\" /usr/lib/\"\$9\" \\n fi\"}' > /tmp/.lib1.tmp" >> /tmp/.D43S.tmp
	echo "ls -l $loc/opt/lib/ | awk '{print \" if [ ! -f /usr/lib/\"\$9\" ] \\n then \\n ln -s $loc/opt/lib/\"\$9\" /usr/lib/\"\$9\" \\n fi\"}' > /tmp/.lib2.tmp" >> /tmp/.D43S.tmp
	echo "ls -l $loc/lib/ | awk '{print \" if [ ! -f /usr/lib/\"\$9\" ] \\n then \\n ln -s $loc/lib/\"\$9\" /usr/lib/\"\$9\" \\n fi\"}' > /tmp/.lib3.tmp" >> /tmp/.D43S.tmp
	echo "sh /tmp/.lib1.tmp ; rm /tmp/.lib1.tmp" >> /tmp/.D43S.tmp
	echo "sh /tmp/.lib2.tmp ; rm /tmp/.lib2.tmp" >> /tmp/.D43S.tmp
	echo "sh /tmp/.lib3.tmp ; rm /tmp/.lib3.tmp" >> /tmp/.D43S.tmp

# EXPERIMENTAL!!!
#cp /tmp/.D43S.tmp /etc/init.d/mountlibs
#chmod 755 /etc/init.d/mountlibs
#ln -s /etc/init.d/mountlibs /etc/rc.d/S98mountlibs
	sh /tmp/.D43S.tmp 2> /dev/null ; rm /tmp/.D43S.tmp
}

Check_ipkg_update()
{
	if  [ ! -s "/usr/lib/ipkg/lists/X-Wrt" ] || [ ! -s "/usr/lib/ipkg/lists/snapshots" ] ; then ipkg update ; fi
}

App_package_install() {
	if ! empty "$FORM_ipkg"; then location="-d "$FORM_ipkg ; fi

	uci_load "app.ipkg"
	ipklocation="$CONFIG_int_location"
	url1=$2

	if equal $(df | grep '/mnt'| awk '{ print $6 }') "" && equal $FORM_ipkg "app" ; then
	echo "<br/><br/><font color=red>Installation path is currently down! Please check your external storage.</font>"
	exit ; fi
	
	echo "Installing $1 package(s) ...<br><br><pre>"
	
	Check_ipkg_update

	if ! equal $3 "" ; then ipkg $location install $url1"$3" -force-overwrite ; fi
	if ! equal $4 "" ; then ipkg $location install $url1"$4" -force-overwrite ; fi
	if ! equal $5 "" ; then ipkg $location install $url1"$5" -force-overwrite ; fi
	if ! equal $6 "" ; then ipkg $location install $url1"$6" -force-overwrite ; fi
	if ! equal $7 "" ; then ipkg $location install $url1"$7" -force-overwrite ; fi
	if ! equal $8 "" ; then ipkg $location install $url1"$8" -force-overwrite ; fi
	if ! equal $9 "" ; then ipkg $location install $url1"$9" -force-overwrite ; fi
}

App_package_remove()
{
	echo "<font size=3>Removing $1 packag(e) ...<br><br><pre>"
	rm /etc/config/$2 2> /dev/null
	if ! equal $3 "" ; then remove_package "$3" ; fi
	if ! equal $4 "" ; then remove_package "$4" ; fi
	if ! equal $5 "" ; then remove_package "$5" ; fi
	if ! equal $6 "" ; then remove_package "$6" ; fi
	if ! equal $7 "" ; then remove_package "$7" ; fi
	if ! equal $8 "" ; then remove_package "$8" ; fi
	if ! equal $9 "" ; then remove_package "$9" ; fi
	echo_remove_complete
}

echo_install_complete() {
	echo "</pre><br/><u>Installation Complete</u>"
}
echo_remove_complete() {
	echo "</pre><br/><u>Uninstall Complete</u>"
}