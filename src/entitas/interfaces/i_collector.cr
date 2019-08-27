module Entitas::ICollector
  include Enumerable(IEntity)
  getter entities : Set(IEntity) = Set(IEntity).new

  abstract def activate
  abstract def deactivate
end
