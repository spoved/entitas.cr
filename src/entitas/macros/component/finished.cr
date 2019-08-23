class Entitas::Component
  macro finished
    {% i = 0 %}
    {% components = [] of TypeString %}
    {% for sub_klass in @type.subclasses %}
      {% components << sub_klass.name %}

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

    create_index({{*components}})

    alias KlassList = Array(
      ::Entitas::Component.class
      {% if @type.subclasses.size == 1 %}
        )? | Array(
        {% for sub_klass in @type.subclasses %}
         ::{{sub_klass.name.id}}.class
        {% end %}
      {% end %}
    )?

    COMPONENT_NAMES = COMPONENT_TO_INDEX_MAP.keys.map &.to_s
    COMPONENT_KLASSES = COMPONENT_TO_INDEX_MAP.keys
  end
end
