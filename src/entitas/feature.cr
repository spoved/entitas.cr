require "./systems"

module Entitas
  class Feature < Systems
    getter name : String

    def initialize(@name); end

    def to_s(io)
      io << name
    end
  end
end
