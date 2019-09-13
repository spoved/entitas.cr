require "http/server"
require "json"

module Entitas
  abstract class Controller
    private property systems : Systems? = nil
    private property contexts : Contexts? = nil

    def start
      self.contexts = Contexts.shared_instance
      self.systems = create_systems(self.contexts.as(Contexts))
      self.systems.as(Systems).init
    end

    def update
      if systems.nil?
        raise "Called update before start! no systems initialized!"
      end
      systems.as(Systems).execute
      systems.as(Systems).cleanup
    end

    abstract def create_systems(contexts : Contexts)

    def stats
      contexts.as(Contexts).all_contexts
    end

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
