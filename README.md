## sconfig
My [OpenBSD](https://www.openbsd.org/) specific objects
used to start/stop the system plus some addons.

License [unlicense](https://unlicense.org)

## bu\_vnstat.sh
To backup
[vnstat port](https://openports.pl/path/net/vnstat)
databases on
[OpenBSD](https://www.openbsd.org/).

## create\_obsd.sh
Generate custom settings that can be sourced in on login.

## restart\_net.sh
Restarts network via /etc/netstart, but will stop wireguard if active.

## rc.local.conf
My rc.local.conf, starts the following:

* [apmd](https://man.openbsd.org/apm),
  settings for use with
  [obsdfreqd](https://tildegit.org/solene/obsdfreqd)
* [obsdfreqd](https://tildegit.org/solene/obsdfreqd)
  settings, I find these help out with the
  [Nvidia Heat](https://www.reddit.com/r/thinkpad/comments/z13jxt/w541_nvidia_heat/)
  issue I had on the Thinkpad W541
* pkg\_scripts -- Services I start
* shlib\_dirs -- my own custom library directory
* sndiod\_flags -- Settings for using
  [BT-W2](https://sg.creative.com/p/speakers/creative-bluetooth-audio-bt-w2-usb-transceiver)
  to enable a Bluetooth Speaker.
* xenodm\_flags --  to start [xenodm](https://man.openbsd.org/xenodm)

## wg\_openbsd.sh
Start/Stop
[wireguard](https://www.wireguard.com/)
client on
[OpenBSD](https://www.openbsd.org/).

## Other Comments
*[Support OpenBSD](https://www.openbsd.org/donations.html)*
