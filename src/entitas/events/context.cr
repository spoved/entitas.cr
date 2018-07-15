require "graphite"
require "../context/context"
require "../entity"

module Entitas
  class ContextEntityChanged < Graphite::EventArgs
    getter context : Entitas::Context
    getter entity : Entitas::Entity

    def initialize(@context, @entity)
    end
  end

  class ContextGroupChanged < Graphite::EventArgs
    getter context : Entitas::Context

    # getter group
    def initialize(@context)
    end
  end
end
