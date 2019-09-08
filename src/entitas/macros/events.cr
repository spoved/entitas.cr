module Entitas::Events
  # Will create `Entitas::Events` struct for the provided `name`. `opts` defines the struct variables.
  #
  # ```
  # create_event OnEntityCreated, {context: Context, entity: Entity}
  # ```
  #
  # This will create the code:
  #
  # ```
  #   struct Entitas::Events::{{name.id}}
  #
  #     getter context : Context
  #     getter entity : Entity
  #
  #     def initialize(context : Context, entity : Entity)
  #     end
  #   end
  # ```
  macro create_event(name, opts)
    struct Entitas::Events::{{name.id}}
      {% for a, t in opts %}
      getter {{a.id}} : {{t.id}}
      {% end %}

      def initialize(
        {% for a, t in opts %}
        @{{a.id}} : {{t.id}},
        {% end %}
      )
      end
    end
  end
end

# Will generate event hook stubs for the provided events
#
# ```
# class Test
#   emits_events OnEntityCreated, OnEntityDestroyed
#
#   # override event methods
#   def on_entity_created(event : Entitas::Events::OnEntityCreated)
#     # do something with event
#   end
# end
#
# obj = Test.new
# obj.on_entity_created(event)   # => does something with event
# obj.on_entity_destroyed(event) # => raises Entitas::Error::MethodNotImplemented
# ```
macro emits_events(*names)
  {% for name in names %}
  emits_event {{name}}
  {% end %}
end

# Will generate event hook stubs for the provided event. Will create `{{name.id.underscore.id}}_event_cache`
# getter/setter as well as `{{name.id.underscore.id}}(event)` method.
#
# ```
# class Test
#   emits_event OnEntityCreated
#
#   # override event methods
#   def on_entity_created(event : Entitas::Events::OnEntityCreated)
#     # do something with event
#   end
# end
#
# obj = Test.new
# obj.on_entity_created(event) # => does something with event
# ```
macro emits_event(name)

  # Method to process event: `Entitas::Events::{{name}}` when emited. Will raise `Entitas::Error::MethodNotImplemented`
  # when not implimented if an `Entitas::Events::{{name}}` is emitted.
  #
  # ```
  # def {{name.id.underscore.id}}(event : Entitas::Events::{{name.id}}) : Nil
  #   # do something with event
  # end
  # ```
  def {{name.id.underscore.id}}(event : Entitas::Events::{{name.id}}) : Nil
    {% if flag?(:entitas_enable_logging) %}logger.info("Processing {{name.id}}: #{event}"){% end %}
    raise Entitas::Error::MethodNotImplemented.new
  end

  property {{name.id.underscore.id}}_event_cache : Proc(Entitas::Events::{{name.id}}, Nil)? = nil

end

macro emit_event(event, *args)
  {% if flag?(:entitas_enable_logging) %}logger.debug("Emitting event {{event.id}}", self.to_s){% end %}
  self.receive_{{event.id.underscore.id}}_event(Entitas::Events::{{event.id}}.new({{*args}}))
end

# Wrapper for multiple `accept_event` calls
macro accept_events(*names)
  {% for name in names %}
  accept_event {{name}}
  {% end %}
end

# Will generate event hook stubs for accepting the provided event. Will create `{{name.id.underscore.id}}_event_hooks`
# array and `{{name.id.underscore.id}}(&block)` method which will append the block to the event hooks array.
#
# The `clear_{{name.id.underscore.id}}_event_hooks` method will clear all the hooks on the object
#
# ```
# class Test
#   accept_event OnEntityCreated
#
#   def initialize
#     on_entity_created_event_hooks.size # => 0
#
#     on_entity_created do |event|
#       # do something with event
#     end
#
#     on_entity_created_event_hooks.size # => 1
#
#     clear_on_entity_created_event_hooks
#
#     on_entity_created_event_hooks.size # => 0
#   end
# end
#
# obj = Test.new
# obj.on_entity_created(event) # => does something with event
# ```
macro accept_event(name)

  # Array of event hooks to trigger when an `Entitas::Events::{{name.id}}` is emitted
  getter {{name.id.underscore.id}}_event_hooks : Array(Proc(Entitas::Events::{{name.id}}, Nil)) = Array(Proc(Entitas::Events::{{name.id}}, Nil)).new

  # Will append the `&block` to the `#{{name.id.underscore.id}}_event_hooks` array
  #
  # ```
  # {{name.id.underscore.id}} do |event|
  #   # do something with event
  # end
  # ```
  def {{name.id.underscore.id}}(&block : Entitas::Events::{{name.id}} -> Nil)
    {% if flag?(:entitas_enable_logging) %}logger.debug("Setting event {{name.id}} hook #{block}", self.to_s){% end %}
    self.{{name.id.underscore.id}}_event_hooks << block
  end

  # Will clear all the event hooks on this instance
  #
  # ```
  # obj.clear_{{name.id.underscore.id}}_event_hooks
  # ```
  private def clear_{{name.id.underscore.id}}_event_hooks : Nil
    self.{{name.id.underscore.id}}_event_hooks.clear
  end

  def remove_{{name.id.underscore.id}}_hook(hook : Proc(Entitas::Events::{{name.id}}, Nil))
    {% if flag?(:entitas_enable_logging) %}logger.debug("Removing event {{name.id}} hook #{hook}", self.to_s){% end %}
    self.{{name.id.underscore.id}}_event_hooks.delete hook
  end

  def receive_{{name.id.underscore.id}}_event(event : Entitas::Events::{{name.id}})
    {% if flag?(:entitas_enable_logging) %}logger.debug("Receiving event {{name.id}}", self.to_s){% end %}

    index = self.{{name.id.underscore.id}}_event_hooks.size - 1
    while index >= 0
      self.{{name.id.underscore.id}}_event_hooks[index].call(event)
      index -= 1
    end
  end
end
