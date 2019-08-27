module Entitas::ICollector
  macro included
    include Enumerable(TEntity)
    getter entities : Set(TEntity) = Set(TEntity).new
  end

  abstract def activate
  abstract def deactivate
end
