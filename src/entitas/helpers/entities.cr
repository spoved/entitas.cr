module Entitas::Helper::Entities
  macro included
    include Enumerable(Entitas::Entity)
    protected getter entities = Set(Entitas::Entity).new
    protected property entities_cache : Array(Entitas::Entity)? = Array(Entitas::Entity).new
  end

  # Determines whether the context has the specified entity.
  def has_entity?(entity : Entitas::Entity) : Bool
    self.entities.includes?(entity)
  end

  # Returns all entities which are currently in the context.
  def get_entities : Array(Entitas::Entity)
    @entities_cache ||= entities.to_a
  end

  ############################
  # Enumerable funcs
  ############################

  # Returns the total number of `Entitas::Entity` in this `Group`
  def size
    self.entities.size
  end

  # See `size`
  def count
    self.size
  end

  def each
    self.entities.each do |entity|
      yield entity
    end
  end
end
