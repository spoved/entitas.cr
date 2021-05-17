module Entitas::IComponent
  Log = ::Log.for(self)

  # Will return true if the class is a unique component for a context
  abstract def is_unique? : Bool
  abstract def init(**args)
  abstract def reset

  macro included
    {% if @type.annotation(::Entitas::Event) %}
      {% for event in @type.annotations(::Entitas::Event) %}
        {% event_target = event.args[0] %}
        {% event_type = event.args[1] %}
        {% event_priority = event.named_args[:priority] %}

        {% contexts = @type.annotations(::Context) %}
        {% for context in contexts %}
          {% for anno in context.args %}
            component_event({{anno.id}}, {{@type.id}}, {{event_target.id}}, {{event_type.id}}, {{event_priority.id}})
            component_event_system({{anno.id}}, {{@type.id}}, {{event_target.id}}, {{event_type.id}}, {{event_priority.id}})
          {% end %}
        {% end %}
      {% end %}
    {% end %}

    Entitas::Component.initializers
  end
end
