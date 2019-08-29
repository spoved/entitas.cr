class Entitas::Component
  macro finished
    {% i = 0 %}
    {% components = [] of TypeString %}
    {% for sub_klass in @type.all_subclasses %}
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

    alias KlassList = Array(
      Entitas::Component.class
      {% if @type.subclasses.size == 1 %}
        )? | Array(
        {% for sub_klass in @type.subclasses %}
         ::{{sub_klass.name.id}}.class
        {% end %}
      {% end %}
    )?

    COMPONENT_NAMES = COMPONENT_TO_INDEX_MAP.keys.map &.to_s
    COMPONENT_KLASSES = COMPONENT_TO_INDEX_MAP.keys.as(KlassList)

    enum Index
      {% begin %}
        {% i = 0 %}
        {% for comp in components %}
          {{comp.id}} = {{i}}
          {% i = i + 1 %}
        {% end %}
      {% end %}
    end

    # A hash to map of enum `Index` to class of `Component`
    INDEX_TO_COMPONENT_MAP = {
      {% for comp in components %}
        Index::{{comp.id}} => ::{{comp.id}},
      {% end %}
    }

    # A hash to map of class of `Component` to enum `Index`
    COMPONENT_TO_INDEX_MAP = {
      {% for comp in components %}
        ::{{comp.id}} => Index::{{comp.id}},
      {% end %}
    }

    # The total number of `Entitas::Component` subclases in this context
    TOTAL_COMPONENTS = {{components.size}}

    # The total amount of components an entity can possibly have.
    def total_components : Int32
      TOTAL_COMPONENTS
    end

    def self.total_components : Int32
      TOTAL_COMPONENTS
    end

    def self.global_index_to_local(index : Entitas::Component::Index) : Int32
      {% i = 0 %}
      case index
      {% for comp in components %}
      when Entitas::Component::Index::{{comp}}
        {{i}}
      {% i = i + 1 %}
      {% end %}
      else
        raise Entitas::Entity::Error::DoesNotHaveComponent.new
      end
    end

  end
end
