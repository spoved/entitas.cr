class Entitas::Context
  protected property entity_indices : Hash(String, Entitas::EntityIndex) = Hash(String, Entitas::EntityIndex).new

  def add_entity_index(entity_index : Entitas::EntityIndex)
    raise Error::EntityIndexDoesAlreadyExist.new(self, entity_index.name) if entity_indices[entity_index.name]?
    entity_indices[entity_index.name] = entity_index
  end

  def get_entity_index(entity_index : Entitas::EntityIndex)
    raise Error::EntityIndexDoesNotExist.new(self, entity_index.name) unless entity_indices[entity_index.name]?
    entity_indices[entity_index.name]
  end
end
