#!/usr/bin/env ruby

require 'serialport'

DEVICE='/dev/cu.usbserial-FTDOMLSO'

port = SerialPort.new(DEVICE, 115200, 8, 1, SerialPort::NONE)

open('/dev/tty', 'r+') { |tty|
  tty.sync = true
  Thread.new {
    while true do
      begin
        tty.putc(port.getc)
      rescue IOError => e
        puts "\nDone"
        exit 0
      end
    end
  }
  while (buf = ARGF.read(30)) do
    port.write(buf)
    sleep(0.02)
  end
}

port.close
