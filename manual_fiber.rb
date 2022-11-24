#!/usr/bin/env ruby

class Server
  attr_reader :server, :requests

  def initialize(port)
    @server = TCPServer.new(port)
    @requests = []
  end

  def start
    loop do
      connection = server.accept_nonblock
      requests.push Fiber.new {
        begin
          message = connection.read_nonblock(1000)
          connection.puts("Response to: #{message}")
        rescue IO::WaitReadable
          Fiber.yield :waiting
          retry
        end
      }
    end
  rescue IO::WaitReadable, Errno::EINTR
    puts "Puts requests in queue: #{requests.size}"
    request = requests.pop
    if request
      result = request.resume
      case result
      when :waiting
        requests.push(request)
      end
    end
    retry
  end

  private

end


server = Server.new(2000)
server.start
