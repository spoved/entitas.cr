module Entitas::Helper::Entities(TEntity)
  macro included
    {% if @type.class? && @type.abstract? %}
      {% verbatim do %}
        include Enumerable(TEntity)
        protected getter entities = Set(TEntity).new
        protected property entities_cache : Array(TEntity)? = Array(TEntity).new
      {% end %}
    {% elsif @type.class? && !@type.abstract? %}
      include Enumerable(TEntity)
      protected getter entities = Set(TEntity).new
      protected property entities_cache : Array(TEntity)? = Array(TEntity).new
    {% end %}
  end

  # Determines whether the context has the specified entity.
  def has_entity?(entity : TEntity) : Bool
    self.entities.includes?(entity)
  end

  # Returns all entities which are currently in the context.
  def get_entities
    @entities_cache ||= entities.to_a
  end

  # Returns a new array with all elements sorted based on the comparator in the
  # given block.
  #
  # The block must implement a comparison between two elements *a* and *b*,
  # where `a < b` returns `-1`, `a == b` returns `0`, and `a > b` returns `1`.
  # The comparison operator `<=>` can be used for this.
  #
  # ```
  # a = [3, 1, 2]
  # b = a.sort { |a, b| b <=> a }
  #
  # b # => [3, 2, 1]
  # a # => [3, 1, 2]
  # ```
  def sort(&block : TEntity, TEntity -> U) : Array(TEntity) forall U
    {% unless U <= Int32? %}
      {% raise "expected block to return Int32 or Nil, not #{U}" %}
    {% end %}

    self.entities.to_a.sort! &block
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
