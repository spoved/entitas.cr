require "json"

# This class gives access to each availble context.
class Entitas::Contexts
  private class_property _shared_instance : Entitas::Contexts? = nil
  private property _all_contexts : Array(Entitas::IContext)? = nil

  # This returns a pre-instantiated `Entitas::Contexts` instance which is available at the global scope.
  #
  # ```
  # Entitas::Contexts.shared_instance # => Entitas::Contexts
  # ```
  def self.shared_instance : Entitas::Contexts
    @@_shared_instance ||= Entitas::Contexts.new
  end

  def shared_instance : Entitas::Contexts
    self.class.shared_instance
  end

  # Will call `Entitas::Context#reset` on each context.
  def reset
    self.all_contexts.each &.reset
  end

  def each
    self.all_contexts.each do |ctx|
      yield ctx
    end
  end

  # Returns the context with the provided name, or nil
  def get_context_by_name(name : String)
    self.all_contexts.find(&.info.name.==(name))
  end

  def initialize
    call_post_constructors
  end

  def to_json(json : JSON::Builder)
    json.object do
      json.field("name", self.class.to_s)
    end
  end
end
