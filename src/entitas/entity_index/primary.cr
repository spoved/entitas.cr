require "./abstract"

class Entitas::PrimaryEntityIndex(TEntity, TKey) < Entitas::AbstractEntityIndex(TEntity, TKey)
  getter index : Hash(TKey, TEntity) = Hash(TKey, TEntity).new

  def get_entity(key : TKey) : TEntity?
    self.index[key]?
  end

  def clear
    index.values.each do |entity|
      if entity.aerc.is_a?(Entitas::SafeAERC)
        entity.release(self) if entity.aerc.includes?(self)
      else
        entity.release(self)
      end
    end
    index.clear
  end

  def add_entity(key : TKey, entity : TEntity)
    if self.index[key]?
      raise Entitas::EntityIndex::Error.new "Entity for key '#{key}' already exists! " \
                                            "Only one entity for a primary key is allowed."
    end

    self.index[key] = entity

    if entity.aerc.is_a?(Entitas::SafeAERC)
      entity.retain(self) unless entity.aerc.includes?(self)
    else
      entity.retain(self)
    end
  end

  def del_entity(key : TKey, entity : TEntity)
    self.index.delete(key)

    if entity.aerc.is_a?(Entitas::SafeAERC)
      entity.release(self) if entity.aerc.includes?(self)
    else
      entity.release(self)
    end
  end

  def to_s(io)
    if self.to_string_cache.nil?
      self.to_string_cache = "PrimaryEntityIndex(#{self.name})"
    else
      io << self.to_string_cache
    end
  end
end
