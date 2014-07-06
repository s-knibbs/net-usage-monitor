Net Usage Monitor
=================

Unity application indicator for displaying the current network usage statistics.

A very simple applet which displays the current download/upload rate and the downloaded/uploaded
data since boot.

Implemented in vala, the code polls the total bytes recieved/transmitted in `/proc/net/netstat`.

Packages required to build:
 * libvala-dev
 * libgee-dev
 * libappindicator-dev
 * libgtk-3-dev 
