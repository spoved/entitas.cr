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

  macro finished

    {% contexts = {} of TypeString => TypeNode %}

    {% for context in Entitas::Context.all_subclasses %}
      {% context_name = context.name.gsub(/Context/, "").underscore %}
      {% contexts[context_name] = context %}
    {% end %}

    {% for context_name, context in contexts %}
    property {{context_name}} : ::{{context.id}} = ::{{context.id}}.new
    {% end %}

    # Returns an array containing each available context
    def all_contexts : Array(Entitas::IContext)
      @_all_contexts ||= [
        {% for context_name, context in contexts %}
          self.{{context_name}},
        {% end %}
      ] of Entitas::IContext
    end

    # Returns the context with the provided name, or nil
    def get_context_by_name(name : String)
      self.all_contexts.find {|ctx| ctx.info.name == name }
    end

    def initialize
      call_post_constructors
    end
  end
end
