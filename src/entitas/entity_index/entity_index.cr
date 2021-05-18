class Entitas::EntityIndex(TEntity, TKey) < Entitas::AbstractEntityIndex(TEntity, TKey)
  getter index : Hash(TKey, Array(TEntity)) = Hash(TKey, Array(TEntity)).new
  delegate :each, to: index

  def [](value : TKey)
    index[value]
  end

  def []?(value : TKey)
    index[value]?
  end

  def clear
    index.values.each do |entities|
      entities.each do |entity|
        if entity.aerc.is_a?(Entitas::SafeAERC)
          entity.release(self) if entity.aerc.includes?(self)
        else
          entity.release(self)
        end
      end
    end
    index.clear
  end

  def add_entity(key : TKey, entity : TEntity)
    {% if flag?(:entitas_enable_logging) %}Log.info { "#{self} - add entity - #{{key: key, entity: entity.to_s}}" }{% end %}

    get_entities(key) << entity

    if entity.aerc.is_a?(Entitas::SafeAERC)
      entity.retain(self) unless entity.aerc.includes?(self)
    else
      entity.retain(self)
    end
  end

  def del_entity(key : TKey, entity : TEntity)
    get_entities(key).delete(entity)

    if entity.aerc.is_a?(Entitas::SafeAERC)
      entity.release(self) if entity.aerc.includes?(self)
    else
      entity.release(self)
    end
  end

  def get_entities(key : TKey) : Array(TEntity)
    unless self.index.has_key?(key)
      self.index[key] = Array(TEntity).new
    end
    self.index[key]
  end

  def to_s(io)
    if self.to_string_cache.nil?
      self.to_string_cache = "EntityIndex(#{self.name})"
    end

    io << self.to_string_cache
  end
end
