CP/M Uploader
=============

This is a client-side tool for sending files to a CP/M machine attached on a
serial port. It assumes Unix/Linux behavior, so probably doesn't work on
Windows machines outside of WSL. For Windows you can use Grant Searle's
binaries [available here](http://searle.x10host.com/cpm/index.html#ROMFiles).

This uses Grant's `DOWNLOAD.COM` program on the CP/M side. The source to that
is available from the link in the previous paragraph. 

If you are running an RC2014 and using Spencer's original distribution of CP/M
on CompactFlash, then the default location of `DOWNLOAD.COM` will work for you.
Otherwise, you will need to pass it on the command line. The following options
are available:

```
Options:
  -d, --download-path=<s>    Path to DOWNLOAD.COM on CP/M (default: A:DOWNLOAD)
  -f, --file=<s>             File to upload
  -u, --user=<i>             The CP/M user ID to upload to (default: 0)
  -p, --port=<s>             The path to the serial port (default: /dev/cu.usbserial-FTDOMLSO)
  -s, --serial-speed=<i>     Serial port speed (default: 115200)
  -h, --help                 Show this message
```

Note that the serial settings assume `8-N-1` behavior. If you need to do
otherwise, you may configure them in the source of the program. since this is
how 99% of terminals will be set, I did not break them out.

This works great on my macOS machine running at 115200. It works just fine with
`minicom` running in another terminal as well.

Installation
------------

You only need to have Ruby installed (most systems do already). Then just run
`gem install bundler` if you don't have bundler. Then `bundle install`. Then
you are ready to go.

Running It
----------

You will want to have already gotten the serial port into a session on CP/M and
have it sitting in the path where you want to upload the file. Make sure it's
at a clean command prompt. You may then invoke it like this from another
terminal window:

```
./upload.rb --file <file to send>
```

You should see the output echoed back from CP/M and then an `OK` at the end. If
you changed the serial port speed to make it faster than 115200, you may need
to adjust the `SEND_DELAY` setting at the top of the file to make it longer.
