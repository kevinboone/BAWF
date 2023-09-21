# Battery-saving Analog Watch Face (BAWF)

Version 0.2, September 2023

![Screenshot](screenshot.png)

This is an extremely simple, non-configurable watch face, originally for the
Garmin Vivoactive 3. It may work on other Garmin products with round faces,
but all I've tested with real hardware are the VA 3 and Venu 2. 

The same code can build white-on-black and black-on white version of
the watch face. White-on-black is probably better on OLED devices
like the Venu 2, because there is no backlight. On LCD devices, 
colour makes no difference to battery life.

The sole purpose of this application is to present an Analog watch
face with the minimum amount of power consumption, to extend battery life.
To that end there is no seconds hand, no dynamically-generated
fitness information, nothing except time and date. I've been very
careful to ensure that the amount of math required to draw the face
is minimized, and repeated calculation avoided.

Thirty-party watch faces for Garmin fitness products are frequently 
blamed for causing battery drain. It's very easy to implement a watch
face carelessly, so that it does too much work, too often. Anything that
displays a second hand will need to redraw at least part of the screen
every second. This watch face is generally updated only once per minute.

## Building

If you're reading this, you probably already know how to build 
ConnectIQ watch face apps. 

I build at the command line like this:

```
monkeyc -o bawf.prg -y /path/to/my/certificate.der -f ./blackonwhite.jungle -d vivoactive3
```

This builds a version with black figures on a white background.
There's also a `whiteonblack.jungle` file to build a white-on-black version.

Instructions on building at the command line are here:

https://developer.garmin.com/connect-iq/reference-guides/monkey-c-command-line-setup/


To run on the simulator:

```
monkeydo bawf.prg vivoactive3
monkeydo bawf.prg venu2 
```

## Installing

To install on a watch, just copy bawf.prg to the `/GARMIN/APPS/` directory
when the watch is mounted as a USB drive.

## Change history
0.2 September 2023
- Bug fixes for Venu-era devices (Garmin has made breaking changes in the
    Monkey C API!)
- Added support for white-on-black, particularly for OLED devices.

 
