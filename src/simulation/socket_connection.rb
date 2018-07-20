require 'socket'

class SocketConnection
  attr_accessor :client

  def initialize
    @connection_error = false
    begin
      address = Configuration::SOCKET_ADDRESS
      port = Configuration::SOCKET_PORT
      @client = TCPSocket.new address, port
    rescue SystemCallError => error
      @connection_error = true
      puts "Error creating the Socket to the server"
      puts error.message
    end
  end

  def send_cm(value)
    begin
      @client.send("#{value}", 0) unless @connection_error
    rescue SystemCallError => error
      puts "Error sending to the socket"
      puts error.message
      @connection_error = true
    end
    puts "Not sending cause connection Error, but would" if @connection_error
    puts "send to socket: #{value}" if @connection_error
  end
end
