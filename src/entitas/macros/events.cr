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

      def to_s(io)
        io << "#{self.class}( "
        {% for a, t in opts %}
          io << "{{a.id}}: "
          @{{a.id}}.to_s(io)
          io << " "
        {% end %}
        io << ")"
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
    {% if flag?(:entitas_enable_logging) %}logger.info("Processing {{name.id}}: #{event}", self.class.to_s){% end %}
    raise Entitas::Error::MethodNotImplemented.new
  end

  property {{name.id.underscore.id}}_event_cache : Proc(Entitas::Events::{{name.id}}, Nil)? = nil

end

macro emit_event(event, *args)
  {% if flag?(:entitas_enable_logging) %}logger.debug("Emitting event {{event.id}}", self){% end %}
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
    {% if flag?(:entitas_enable_logging) %}logger.debug("Setting event {{name.id}} hook #{block}", self){% end %}
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
    {% if flag?(:entitas_enable_logging) %}logger.debug("Removing event {{name.id}} hook #{hook}", self){% end %}
    self.{{name.id.underscore.id}}_event_hooks.delete hook
  end

  def receive_{{name.id.underscore.id}}_event(event : Entitas::Events::{{name.id}})
    {% if flag?(:entitas_enable_logging) %}logger.debug("Receiving event {{name.id}}", self){% end %}

    index = self.{{name.id.underscore.id}}_event_hooks.size - 1
    while index >= 0
      self.{{name.id.underscore.id}}_event_hooks[index].call(event)
      index -= 1
    end
  end
end

macro component_event(context, comp, target, _type = EventType::Added, priority = 1)

  {% priority = 1 if priority.id == "nil" %}
  {% _type = "EventType::Added" if _type.id == "nil" %}
  {% component_name = comp.id.gsub(/^.*::/, "") %}
  {% component_namespace = "#{comp.id.gsub(/::.*$/, "")}::" %}
  {% component_meth_name = component_name.underscore %}
  {% context_meth_name = context.stringify.underscore %}

  {% listener = _type.id == "EventType::Removed" ? "RemovedListener" : "Listener" %}

  {% if target.id == "EventTarget::Any" %}
    {% listener_module = "::#{comp.id}::Any#{listener.id}" %}
    {% listener_component_module = "#{component_namespace.id}Any#{component_name.id}#{listener.id}" %}
    {% listener_component_name = "Any#{component_name.id}#{listener.id}" %}
    {% system_name = "::#{context.id}::EventSystem::#{component_name.id}::Any#{listener.id}" %}
  {% else %}
    {% listener_module = "::#{comp.id}::#{listener.id}" %}
    {% listener_component_module = "#{component_namespace.id}#{component_name.id}#{listener.id}" %}
    {% listener_component_name = "#{component_name.id}#{listener.id}" %}
    {% system_name = "::#{context.id}::EventSystem::#{component_name.id}::#{listener.id}" %}
  {% end %}

  {% listener_component_meth_name = listener_component_name.underscore %}

  module {{listener_module.id}}
    {% if _type.id == "EventType::Removed" %}
      abstract def on_{{component_meth_name.id}}(entity)
    {% else %}
      abstract def on_{{component_meth_name.id}}(entity, component : {{comp.id}} )
    {% end %}
  end

  @[::Context({{context.id}})]
  class {{listener_component_module.id}} < Entitas::Component
    prop :value, Set({{listener_module.id}}), default: Set({{listener_module.id}}).new

    def to_s(io)
      io << "{{listener_component_name.id}}("
      value.class.to_s(io) 
      io << ")"
    end
  end

  module ::{{comp.id}}::Helper
    def add_{{listener_component_meth_name.id}}(value : {{listener_module.id}})
      {% if flag?(:entitas_enable_logging) %}logger.debug("add_{{listener_component_meth_name.id}} - value: #{value}", self){% end %}

      %listeners = self.{{listener_component_meth_name.id}}? ? self.{{listener_component_meth_name.id}}.value : Set({{listener_module.id}}).new
      %listeners << value
      {% if flag?(:entitas_enable_logging) %}logger.debug("add_{{listener_component_meth_name.id}} - total listeners: #{%listeners.size}", self){% end %}
      self.replace_{{listener_component_meth_name.id}}(%listeners)
      {% if flag?(:entitas_enable_logging) %}logger.debug("add_{{listener_component_meth_name.id}} - total listeners: #{self.{{listener_component_meth_name.id}}.value.size}", self){% end %}
    end

    def remove_{{listener_component_meth_name.id}}(value : {{listener_module.id}}, remove_comp_when_empty = false)
      {% if flag?(:entitas_enable_logging) %}logger.debug("remove_{{listener_component_meth_name.id}} - remove_comp_when_empty: #{remove_comp_when_empty}, value: #{value}", self){% end %}
      %listeners = self.{{listener_component_meth_name.id}}.value
      %listeners.delete(value)
      if(remove_comp_when_empty && %listeners.empty?)
        self.del_{{listener_component_meth_name.id}}
      else
        self.replace_{{listener_component_meth_name.id}}(%listeners)
      end
    end
  end
end

macro component_event_system(context, comp, target, _type = EventType::Added, priority = 1)
  {% priority = 1 if priority.id == "nil" %}
  {% _type = "EventType::Added" if _type.id == "nil" %}
  {% component_name = comp.id.gsub(/^.*::/, "") %}
  {% component_namespace = "#{comp.id.gsub(/::.*$/, "")}::" %}
  {% component_meth_name = component_name.underscore %}
  {% context_meth_name = context.stringify.underscore %}

  {% listener = _type.id == "EventType::Removed" ? "RemovedListener" : "Listener" %}

  {% if target.id == "EventTarget::Any" %}
    {% listener_module = "::#{comp.id}::Any#{listener.id}" %}
    {% listener_component_module = "#{component_namespace.id}Any#{component_name.id}#{listener.id}" %}
    {% listener_component_name = "Any#{component_name.id}#{listener.id}" %}
    {% system_name = "::#{context.id}::EventSystem::#{component_name.id}::Any#{listener.id}" %}
  {% else %}
    {% listener_module = "::#{comp.id}::#{listener.id}" %}
    {% listener_component_module = "#{component_namespace.id}#{component_name.id}#{listener.id}" %}
    {% listener_component_name = "#{component_name.id}#{listener.id}" %}
    {% system_name = "::#{context.id}::EventSystem::#{component_name.id}::#{listener.id}" %}
  {% end %}

  {% listener_component_meth_name = listener_component_name.underscore %}

  @[EventSystem(context: {{context.id}}, priority: {{priority}})]
  class {{system_name.id}} < Entitas::ReactiveSystem
    protected property contexts : Contexts
    protected property context : ::{{context.id}}Context
    protected property listener_buffer : Set({{listener_module.id}}) = Set({{listener_module.id}}).new

    {% if target.id == "EventTarget::Any" %}
      protected property listeners : Entitas::Group({{context.id}}Entity)
      protected property entity_buffer : Set({{context.id}}Entity) = Set({{context.id}}Entity).new
    {% end %}

    def initialize(@contexts : Contexts)
      @context = @contexts.{{context_meth_name.id}}
      @collector = get_trigger(@context)

      {% if target.id == "EventTarget::Any" %}
        # @listeners = @context.get_group({{context.id}}Matcher.{{listener_component_meth_name.id}})

        @listeners = @context.get_group(
          {{context.id}}Context.matcher.all_of(
            Entitas::Component::Index::{{listener_component_name.id}}
          )
        )
        {% if flag?(:entitas_enable_logging) %}logger.debug("Added listeners #{@listeners}", self){% end %}
      {% end %}
      {% if flag?(:entitas_enable_logging) %}logger.debug("Added collector #{@collector}", self){% end %}
    end

    def get_trigger(context : Entitas::Context) : Entitas::ICollector
      context.create_collector(
        {% if _type.id == "EventType::Removed" %}
          {{context.id}}Context.matcher.all_of(
            Entitas::Component::Index::{{component_name.id}}
          ).removed
        {% else %}
          {{context.id}}Context.matcher.all_of(
            Entitas::Component::Index::{{component_name.id}}
          ).added
        {% end %}
      )
    end

    def filter(entity : {{context.id}}Entity)
      {% if target.id == "EventTarget::Self" && _type.id == "EventType::Added" %}
        entity.{{listener_component_meth_name.id}}? && entity.{{component_meth_name.id}}?
      {% elsif target.id == "EventTarget::Self" && _type.id == "EventType::Removed" %}
        entity.{{listener_component_meth_name.id}}? && !entity.{{component_meth_name.id}}?
      {% elsif target.id == "EventTarget::Any" && _type.id == "EventType::Added" %}
        entity.{{component_meth_name.id}}?
      {% elsif target.id == "EventTarget::Any" && _type.id == "EventType::Removed" %}
        !entity.{{component_meth_name.id}}?
      {% end %}
    end

    def execute(entities : Array(Entitas::IEntity))
      entities.each do |entity|
        entity = entity.as({{context.id}}Entity)
        # {{component_name}} - {{target.id}} - {{_type.id}}
        {% if flag?(:entitas_enable_logging) %}logger.info("execute - {{component_name}} - {{target.id}} - {{_type.id}} - #{entity}", self){% end %}

        {% if target.id == "EventTarget::Self" && _type.id == "EventType::Added" %}
          comp = entity.{{component_meth_name.id}}
          {% if flag?(:entitas_enable_logging) %}logger.debug("[Event:Self:Added] execute - component: #{comp.to_s}", self){% end %}
          self.listener_buffer.clear
          self.listener_buffer.concat(entity.{{listener_component_meth_name.id}}.value)
          {% if flag?(:entitas_enable_logging) %}logger.debug("[Event:Self:Added] execute - total listeners: #{listener_buffer.size}", self){% end %}
          self.listener_buffer.each do |listener|
            {% if flag?(:entitas_enable_logging) %}logger.debug("[Event:Self:Added] execute - calling listener: #{listener}", self){% end %}
            listener.on_{{component_meth_name.id}}(entity, comp)
          end
        {% elsif target.id == "EventTarget::Self" && _type.id == "EventType::Removed" %}
          self.listener_buffer.clear
          self.listener_buffer.concat(entity.{{listener_component_meth_name.id}}.value)
          {% if flag?(:entitas_enable_logging) %}logger.debug("[Event:Self:Removed] execute - total listeners: #{listener_buffer.size}", self){% end %}
          self.listener_buffer.each do |listener|
            {% if flag?(:entitas_enable_logging) %}logger.debug("[Event:Self:Removed] execute - calling listener: #{listener}", self){% end %}
            listener.on_{{component_meth_name.id}}(entity)
          end
        {% elsif target.id == "EventTarget::Any" && _type.id == "EventType::Added" %}
          comp = entity.{{component_meth_name.id}}
          {% if flag?(:entitas_enable_logging) %}logger.debug("[Event:Any:Added] execute - component: #{comp.to_s}", self){% end %}
          self.listeners.get_entities(self.entity_buffer).each do |listener_entity|
            {% if flag?(:entitas_enable_logging) %}logger.debug("[Event:Any:Added] execute - listener_entity: #{listener_entity}", self){% end %}
            self.listener_buffer.clear
            self.listener_buffer.concat(listener_entity.{{listener_component_meth_name.id}}.value)
            {% if flag?(:entitas_enable_logging) %}logger.debug("[Event:Any:Added] execute - total listeners: #{listener_buffer.size}", self){% end %}
            self.listener_buffer.each do |listener|
              {% if flag?(:entitas_enable_logging) %}logger.debug("[Event:Any:Added] execute - calling listener: #{listener}", self){% end %}
              listener.on_{{component_meth_name.id}}(entity, comp)
            end
          end
        {% elsif target.id == "EventTarget::Any" && _type.id == "EventType::Removed" %}
          self.listeners.get_entities(self.entity_buffer).each do |listener_entity|
            {% if flag?(:entitas_enable_logging) %}logger.debug("[Any:Removed] execute - listener_entity: #{listener_entity}", self){% end %}
            self.listener_buffer.clear
            self.listener_buffer.concat(listener_entity.{{listener_component_meth_name.id}}.value)
            {% if flag?(:entitas_enable_logging) %}logger.debug("[Any:Removed] execute - total listeners: #{listener_buffer.size}", self){% end %}
            self.listener_buffer.each do |listener|
              {% if flag?(:entitas_enable_logging) %}logger.debug("[Any:Removed] execute - calling listener: #{listener}", self){% end %}
              listener.on_{{component_meth_name.id}}(entity)
            end
          end
        {% else %}
          raise "Invalid event {{component_name}} - {{target.id}} - {{_type.id}}"
        {% end %}
      end
    end
  end
end
