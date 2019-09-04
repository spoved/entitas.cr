module Entitas::IEntityIndex
  abstract def name : String
  abstract def activate : Nil
  abstract def deactivate : Nil

  property to_string_cache : String? = nil

  def to_s(io)
    if self.to_string_cache.nil?
      self.to_string_cache = "#{self.class}(#{self.name})"
    else
      io << self.to_string_cache
    end
  end
end
