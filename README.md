# toddlers-first-asterisk
A simple asterisk configuration with a single digit dialplans for a toddler to
learn how to use an analogue phone

Build with:
```
$ sudo build.sh
```

The build script starts asterisk.

I was unable to get Asterisk to work in a docker container, but it is straight
forward to get it running in an lxd container.


# PAP2 Configuration

To configure a Linksys PAP2 to connect to Asterisk:

| Configuration Page | Key       | Value              | Source of value in Asterisk |
| -                  | -         | -                  | -                           |
| Line 1             | SIP Port  | 5060               | (Default value)             |
|                    | User ID   | 6001               | `/etc/asterisk/pjsip.conf`: Group name and `6001.username=6001 |
|                    | Password  | `unsecurepassword` | `/etc/asterisk/pjsip.conf`: `6001.password=unsecurepassword` |
|                    | Dial Plan | `x`                | Implicitly required based on the content of `/etc/asterisk/extensions.conf` |


# Debugging Asterisk

Connect to the Asterisk console with
```
sudo asterisk -r
```


# `.wav` Files


