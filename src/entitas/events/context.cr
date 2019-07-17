require "../context/context"
require "../entity"

module Entitas
  class ContextEntityChanged
    getter context : Entitas::Context
    getter entity : Entitas::Entity

    def initialize(@context, @entity)
    end
  end

  class ContextGroupChanged
    getter context : Entitas::Context

    # getter group
    def initialize(@context)
    end
  end
end
