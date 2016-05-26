#!/usr/bin/env ruby

require 'socket'
require 'shellwords'

$fds_read = []
$cmd = nil

ConnectionPair = Struct.new :socket, :process, 
                            :udp_from, :udp_data, :udp_fd

$conn_map = {}

def listen_tcp addr, port
  $fds_read.push TCPServer.new addr, port
end

def listen_udp addr, port
  fd = UDPSocket.new
  fd.bind addr, port
  $fds_read.push fd
end

def on_data s, data
  if ! $conn_map[s]
    p = IO.popen(["sh", "-c", $cmd], 'r+')
    c = ConnectionPair.new s, p
    $conn_map[s] = c
    $conn_map[p] = c
    $fds_read.push p
  end
  c = $conn_map[s]
  peer = c.socket == s ? c.process : c.socket
  if peer
    peer.write(data)
  else
    c.udp_data += data
  end
end

def on_udp data, from, local_fd
  p = IO.popen(["sh", "-c", $cmd], 'r+')
  c = ConnectionPair.new nil, p, from, "", local_fd
  p.write data
  p.close_write
  $conn_map[p] = c
  $fds_read.push p
end

def on_close s
  puts s
  if $conn_map[s]
    c = $conn_map[s]
    if s == c.socket
      # remote closed
      $fds_read.delete c.socket
      $conn_map.delete c.socket
      c.process.close_write
    else
      # local closed
      $fds_read.delete c.process
      $conn_map.delete c.process
      if c.socket
        c.socket.close_write
      else
        c.udp_fd.send c.udp_data, 0, c.udp_from[3], c.udp_from[1]
      end
      Process.waitpid c.process.pid
    end
  else
    # not mapped, just close and remove
    $fds_read.delete s
    s.close
  end
end

def run_loop
  loop do
    r, = select($fds_read)
    r.each do |s|
      if s.is_a? TCPServer
        client = s.accept
        $fds_read.push client
      elsif s.is_a? UDPSocket
        x = s.recvfrom_nonblock 65536
        on_udp(x[0], x[1], s)
      else
        begin
          x = s.read_nonblock 64 * 1024
          on_data(s, x)
        rescue EOFError
          on_close(s)
        end
      end
    end
  end
end

def usage
  puts "#{$0} [-t [addr:]port] [-u [addr:]port] command"
  exit 1
end

def parse_args
  listened = false
  args = Array.new ARGV
  while args.length > 0
    arg = args.shift
    if arg =~ /^-(.)/
      case $1
      when 't'
        port = args.shift
        addr = "0.0.0.0"
        if port =~ /:/
          addr, port = port.split ':', 2
        end
        listen_tcp addr, port
        listened = true
      when 'u'
        port = args.shift
        addr = "0.0.0.0"
        if port =~ /:/
          addr, port = port.split ':', 2
        end
        listen_udp addr, port
        listened = true
      else
        raise "Unknown argument #{arg}"
      end
    else
      args.unshift arg
      $cmd = Shellwords.join args
      break
    end
  end
  if !listened or !$cmd
    usage
  end
end

parse_args
run_loop
