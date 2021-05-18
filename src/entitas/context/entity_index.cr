class Entitas::Context(TEntity)
  @entity_indices : Hash(String, Entitas::IEntityIndex) = Hash(String, Entitas::IEntityIndex).new

  def add_entity_index(entity_index : Entitas::IEntityIndex)
    raise EntityIndex::Error::AlreadyExists.new(self, entity_index.name) if entity_indices[entity_index.name]?
    entity_indices[entity_index.name] = entity_index
  end

  def get_entity_index(name : String) : Entitas::IEntityIndex
    raise EntityIndex::Error::DoesNotExist.new(self, name) unless entity_indices[name]?
    entity_indices[name]
  end

  def get_entity_index?(name : String) : Entitas::IEntityIndex?
    entity_indices[name]?
  end

  def entity_indices : Hash(String, Entitas::IEntityIndex)
    @entity_indices
  end
end
