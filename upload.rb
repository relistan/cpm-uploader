#!/usr/bin/env ruby

# This tool is used to upload files to CP/M machines attached to the serial
# port. It assumes you are already in CP/M and in the path where you want to
# upload the file. Relies on hardware flow control. The CP/M side is assumed
# to be Grant Searle's DOWNLOAD.COM utility.
#
# Karl Matthias -- April 2022

require 'optimist'
require 'serialport'

READ_BLOCK_SIZE = 5
DEFAULT_DEVICE = '/dev/cu.usbserial-FTDOMLSO'

opts = Optimist::options do
  opt :download_path, 'Path to DOWNLOAD.COM on CP/M', type: :string, default: 'A:DOWNLOAD'
  opt :file, 'File to upload', type: :string, short: 'f', required: true
  opt :user, 'The CP/M user ID to upload to', type: :integer, default: 0
  opt :port, 'The path to the serial port', type: :string, default: DEFAULT_DEVICE
  opt :serial_speed, 'Serial port speed', type: :int, default: 115200
end

def sanitize_cpm_filename(filename)
  File.basename(filename).upcase.gsub(/[^A-Z0-9\-.]*/, '')
end

def to_hex(int)
  int.to_s(16).rjust(2, '0').upcase
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
port.flow_control = SerialPort::HARD

# Open tty for output
tty = open('/dev/tty', 'r+')
follow_tty(tty, port)

# Output the header
cpm_filename = sanitize_cpm_filename(opts[:file])
port_write(port, "\n#{opts[:download_path]} #{cpm_filename}\nU#{opts[:user]}\n:")

count = 0

# Process the file
while (buf = infile.read(READ_BLOCK_SIZE)) do
  checksum = buf.each_byte.inject(checksum) { |memo, byte| memo = (memo + byte) & 0xFF}
  byte_count = (byte_count + buf.bytesize) & 0xFF

  # Output to the port
  port_write(port, buf.unpack('H*').flatten.first.upcase)
end

# Output the closing statement
port.puts ">#{to_hex(byte_count)}#{to_hex(checksum)}"

sleep(0.1) # Just enough time for final output
infile.close
port.close
