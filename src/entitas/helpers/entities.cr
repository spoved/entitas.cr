module Entitas::Helper::Entities(TEntity)
  macro included
    include Enumerable(TEntity)
    protected getter entities = Set(TEntity).new
    protected property entities_cache : Array(TEntity)? = Array(TEntity).new
  end

  # Determines whether the context has the specified entity.
  def has_entity?(entity : TEntity) : Bool
    self.entities.includes?(entity)
  end

  # Returns all entities which are currently in the context.
  def get_entities : Array(TEntity)
    @entities_cache ||= entities.to_a
  end

  ############################
  # Enumerable funcs
  ############################

  # Returns the total number of `TEntity` in this `Group`
  def size
    self.entities.size
  end

  # See `size`
  def count : Int32
    self.size
  end

  def each(&block : TEntity -> Nil)
    self.entities.each do |entity|
      yield entity
    end
  end
end
