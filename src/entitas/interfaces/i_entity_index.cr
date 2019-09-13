module Entitas::IEntityIndex
  abstract def name : String
  abstract def activate : Nil
  abstract def deactivate : Nil

  property to_string_cache : String? = nil

  def to_json(json)
    json.object do
      json.field "name", name
    end
  end

  def to_s(io)
    if self.to_string_cache.nil?
      self.to_string_cache = "#{self.class}(#{self.name})"
    end
    io << self.to_string_cache
  end
end
