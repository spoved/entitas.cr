require "http/server"
require "json"

module Entitas
  abstract class Controller
    def start_server
      spawn do
        server = HTTP::Server.new do |context|
          context.response.content_type = "application/json"
          context.response.headers["Access-Control-Allow-Origin"] = "*"
          context.response.headers["Access-Control-Allow-Methods"] = "GET"
          context.response.headers["Access-Control-Allow-Headers"] = "Content-Type"
          context.response.print (stats).to_json
        end

        puts "Listening on http://127.0.0.1:8080"
        server.listen(8080)
      end
    end
  end
end
