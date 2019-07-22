module Entitas
  abstract class Component
    macro finished
      {% begin %}
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

        {% for context_ann, comp_array in context_map %}
          {% comp_array = comp_array.uniq %}
          {% context_name = context_ann[0] %}

          create_entity_for_context({{context_name}})

          class ::{{context_name.id}}Context < ::Entitas::Context

            {% i = 0 %}

            enum Index
              {% for comp in comp_array %}
              {{comp.name.id}} = {{i}}
              {% i = i + 1 %}
              {% end %}
            end

            CONTEXT_NAME = "{{context_name.id}}Context"

            # A hash to map of enum `Index` to class of `Component`
            INDEX_TO_COMPONENT_MAP = {
            {% for comp in comp_array %}
              Index::{{comp.name.id}} => ::{{comp.name.id}},
            {% end %}
            }

            # A hash to map of class of `Component` to enum `Index`
            COMPONENT_TO_INDEX_MAP = {
              {% for comp in comp_array %}
                ::{{comp.name.id}} => Index::{{comp.name.id}},
              {% end %}
            }

            # The total number of `::Entitas::Component` subclases in this context
            TOTAL_COMPONENTS = {{comp_array.size}}

            # Unique components
            UNIQUE_COMPONENTS = [
              {% for comp in comp_array %}
                {% if comp.annotation(::Component::Unique) %}
                  ::{{comp.name.id}},
                {% end %}
              {% end %}
            ]

            # The total amount of components an entity can possibly have.
            def total_components : Int32
              TOTAL_COMPONENTS
            end

            def klass_to_index(klass)
              raise Entitas::Entity::Error::DoesNotHaveComponent.new unless COMPONENT_TO_INDEX_MAP[klass]?

              COMPONENT_TO_INDEX_MAP[klass]
            rescue
              raise Entitas::Entity::Error::DoesNotHaveComponent.new
            end

            def component_pool(index : Index) : ::Entitas::ComponentPool
              component_pool index.value
            end

            private def create_default_context_info : Entitas::Context::Info
              logger.debug "Creating default context", CONTEXT_NAME

              component_names = Array(String).new
              prefix = "Index "
              total_components.times do |i|
                component_names << prefix + i.to_s
              end

              Entitas::Context::Info.new(CONTEXT_NAME, component_names, COMPONENT_TO_INDEX_MAP.keys)
            end

            def entity_factory : ::{{context_name.id}}Entity
              ::{{context_name.id}}Entity.new(
                creation_index,
                total_components,
                component_pools,
              )
            end
          end
        {% end %}
      {% end %}
    end
  end
end
