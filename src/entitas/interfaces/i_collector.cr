module Entitas::ICollector(TEntity)
  include Enumerable(TEntity)
  getter entities : Set(TEntity) = Set(TEntity).new

  abstract def activate
  abstract def deactivate
end
