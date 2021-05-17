class Entitas::Context(TEntity); end

# Process EventSystem annotations
# :nodoc:
macro generate_event_systems
  {% begin %}
    {% event_systems_map = {} of TypeNode => ArrayLiteral(Annotation) %}
    {% for obj in Object.all_subclasses.sort_by(&.name) %}
      {% if obj.annotation(EventSystem) %}
        {% for anno in obj.annotations(EventSystem) %}
          {% context = anno.named_args[:context] %}
          {% array = event_systems_map[context] %}
          {% if array == nil %}
            {% event_systems_map[context] = [obj] %}
          {% else %}
            {% event_systems_map[context] = array + [obj] %}
          {% end %}
        {% end %}
      {% end %}
    {% end %}

    {% for context in event_systems_map %}
      class ::{{context.id}}::EventSystems < ::Entitas::Feature
        def initialize(contexts : Contexts)
          @name = "{{context.id}}::EventSystems"
          {% for sys in event_systems_map[context].sort_by { |a| a.annotation(EventSystem).named_args[:priority] } %}
            add({{sys.id}}.new(contexts))
          {% end %}
        end
      end
    {% end %}
  {% end %}
end
