require "./context/*"

class Entitas::Context
  macro create_contexts_klass(*contexts)
    class ::Contexts
      private class_property _shared_instance : ::Contexts? = nil

      def self.shared_instance
        self._shared_instance ||= ::Contexts.new
      end

    {% for context_name in contexts %}
      property {{context_name.id.underscore.id}} : ::{{context_name.id}}Context = ::{{context_name.id}}Context.new
    {% end %}

      def all_contexts : Array(Entitas::Context)
        [
          {% for context_name in contexts %}
          self.{{context_name.id.underscore.id}},
          {% end %}
        ]
      end

      def reset
        self.all_contexts.each &.reset
      end
    end
  end

  macro create_sub_context(context_name, *components)
    class ::{{context_name.id}}Context < ::Entitas::Context
      CONTEXT_NAME = "{{context_name.id}}Context"

      Entitas::Component.create_index({{*components}})
      Entitas::Component.create_class_helpers({{*components}})
      Entitas::Component.create_instance_helpers(::{{context_name.id}}Context)

      private def create_default_context_info : Entitas::Context::Info
        {% if !flag?(:disable_logging) %}logger.debug("Creating default context", CONTEXT_NAME){% end %}

        @component_names_cache.clear
        prefix = "Index "
        total_components.times do |i|
          @component_names_cache << prefix + i.to_s
        end

        Entitas::Context::Info.new(
          CONTEXT_NAME,
          component_names_cache,
          COMPONENT_TO_INDEX_MAP.keys
        )
      end

      def entity_factory : ::{{context_name.id}}Entity
        ::{{context_name.id}}Entity.new(
          creation_index,
          total_components,
          component_pools,
        )
      end
    end
  end
end

class Entitas::Component
  # Generate Contexts
  macro finished
    {% begin %}
      # Cycle through each annotation for context
      {% context_map = {} of Annotation => ArrayLiteral(TypeNode) %}
      {% for sub_klass in @type.subclasses %}
        {% for ann, idx in sub_klass.annotations(::Context) %}
          {% array = context_map[ann] %}
          {% if array == nil %}
            {% context_map[ann] = [sub_klass] %}
          {% else %}
            {% context_map[ann] = array + [sub_klass] %}
          {% end %}
        {% end %}
      {% end %}

      {% contexts = [] of TypePath %}
      {% for context_ann, comp_array in context_map %}
        {% comp_array = comp_array.uniq %}
        {% context_name = context_ann[0] %}
        {% contexts << context_name %}

        Entitas::Entity.create_entity_for_context({{context_name}}, [
          {% for comp in comp_array %}
          {{comp.name.id}},
          {% end %}
        ])

        Entitas::Matcher.create_matcher_for_context({{context_name}}, [
          {% for comp in comp_array %}
          {{comp.name.id}},
          {% end %}
        ])

        Entitas::Context.create_sub_context({{context_name}},
          {% for comp in comp_array %}
          {{comp.name.id}},
          {% end %}
        )
      {% end %}

      Entitas::Context.create_contexts_klass({{*contexts}})
    {% end %}
  end
end
