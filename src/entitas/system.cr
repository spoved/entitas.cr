module Entitas
  module System
    def to_json(json : JSON::Builder)
      json.object do
        json.field("name", self.class.to_s)
      end
    end
  end
end
