module Entitas
  abstract class Component
    # Will create getter/setter for the provided `var`, ensuring its type
    macro prop(var, kype, **kwargs)
      {% if kwargs[:default] %}
        property {{ var.id }} : {{kype}} = {{ kwargs[:default] }}

        # This is a private methods used for code generation
        private def _entitas_set_{{ var.id }}(value : {{kype}} = {{ kwargs[:default] }})
          @{{ var.id }} = value
        end
      {% else %}
        property {{ var.id }} : {{kype}}? = nil

        # This is a private methods used for code generation
        private def _entitas_set_{{ var.id }}(value : {{kype}})
          @{{ var.id }} = value
        end
      {% end %}
    end

    abstract def index_val : Int32
    abstract def index : Entitas::Component::Index

    macro finished
      {% i = 0 %}

      {% for sub_klass in @type.subclasses %}
        class ::{{sub_klass.name.id}}

          INDEX = Entitas::Component::Index::{{sub_klass.name.id}}
          INDEX_VALUE = {{i}}

          def self.index_val : Int32
            INDEX_VALUE
          end

          def index_val : Int32
            INDEX_VALUE
          end

          def self.index : Entitas::Component::Index
            INDEX
          end

          def index : Entitas::Component::Index
            INDEX
          end
        end
      {% i = i + 1 %}
      {% end %}
    end
  end
end
