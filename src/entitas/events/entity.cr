require "graphite"
require "../entity"

module Entitas
  class EntityEvent < Graphite::EventArgs
    getter entity : Entitas::Entity

    def initialize(@entity)
    end
  end
end
