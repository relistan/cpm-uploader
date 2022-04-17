#!/usr/bin/env ruby

READ_BLOCK_SIZE = 30

require 'optimist'
opts = Optimist::options do
  opt :download_path, 'Path to DOWNLOAD.COM on CP/M', type: :string, default: 'A:DOWNLOAD.COM'
  opt :file, 'File to upload', type: :string, short: 'f', required: true
  opt :user, 'The CP/M user ID to upload to', type: :integer, default: 0
end

def print_header

end

unless File.exists?(opts[:file])
  abort "Cannot find file: #{opts[:file]}"
end

infile = begin
  File.open(opts[:file], 'r')
rescue => e
  abort "Unable to open file '#{opts[:file]}': #{e}"
end

puts "#{opts[:download_path]} #{opts[:file].upcase}"
puts "U#{opts[:user]}"
print ':'

# Initialize some things we track
checksum = 0
byte_count = 0

# Process the file
while (buf = infile.read(READ_BLOCK_SIZE)) do
  checksum = buf.each_byte.inject(checksum) { |memo, checksum| memo += checksum } & 0xFF
  print buf.unpack('H*').flatten.first.upcase
  byte_count = (byte_count + buf.size) & 0xFF
end

# Output the closing statement
puts ">#{byte_count}#{checksum}"

infile.close
