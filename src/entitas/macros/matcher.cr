require "./matcher/*"

class Entitas::Matcher
  macro create_matcher_for_context(context_name, components)
      class ::{{context_name.id}}Matcher < ::Entitas::Matcher
        {% for comp in components %}

        class_getter {{comp.id.underscore}} = Entitas::Matcher.all_of({{comp.id}})

        {% end %}
      end
  end
end
