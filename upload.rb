#!/usr/bin/env ruby

# This tool is used to upload files to CP/M machines attached to the serial
# port. It assumes you are already in CP/M and in the path where you want to
# upload the file.
#
# Karl Matthias -- April 2022

require 'optimist'
require 'serialport'

READ_BLOCK_SIZE = 30
DEFAULT_DEVICE = '/dev/cu.usbserial-FTDOMLSO'
SEND_DELAY = 0.03 # Seconds

opts = Optimist::options do
  opt :download_path, 'Path to DOWNLOAD.COM on CP/M', type: :string, default: 'A:DOWNLOAD'
  opt :file, 'File to upload', type: :string, short: 'f', required: true
  opt :user, 'The CP/M user ID to upload to', type: :integer, default: 0
  opt :port, 'The path to the serial port', type: :string, default: DEFAULT_DEVICE
  opt :serial_speed, 'Serial port speed', type: :int, default: 115200
end

# Output everything to the tty that we get from the serial port
def follow_tty(tty, port)
  tty.sync = true
  Thread.new do
    while true do
      begin
        tty.putc(port.getc)
      rescue IOError => e
        puts "\nDone"
        exit 0
      end
    end
  end
end

def port_write(port, buf)
  port.write(buf)
  sleep(SEND_DELAY) # Make sure not to overrun serial buffer
end

unless File.exists?(opts[:file])
  abort "Cannot find file: #{opts[:file]}"
end

infile = begin
  File.open(opts[:file], 'r')
rescue => e
  abort "Unable to open file '#{opts[:file]}': #{e}"
end

# Initialize some things we track
checksum = 0
byte_count = 0

# Set up the serial port
port = SerialPort.new(opts[:port], opts[:serial_speed], 8, 1, SerialPort::NONE)

# Open tty for output
tty = open('/dev/tty', 'r+')
follow_tty(tty, port)

# Output the header
port_write(port, "\n#{opts[:download_path]} #{opts[:file].upcase}\nU#{opts[:user]}\n:")

# Process the file
while (buf = infile.read(READ_BLOCK_SIZE)) do
  checksum = buf.each_byte.inject(checksum) { |memo, byte| memo = (memo + byte) & 0xFF}
  byte_count = (byte_count + buf.bytesize) & 0xFF

  # Output to the port
  port_write(port, buf.unpack('H*').flatten.first.upcase)
end

# Output the closing statement
port.puts ">#{byte_count.to_s(16).upcase}#{checksum.to_s(16).upcase}"

sleep(0.1) # Just enough time for final output
infile.close
port.close
