class Entitas::Component
  macro create_index(*components)
    {% i = 0 %}
    enum Index
      {% for comp in components %}
      {{comp.id}} = {{i}}
      {% i = i + 1 %}
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

    # The total number of `::Entitas::Component` subclases in this context
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

  macro create_class_helpers(*components)

    def self.component_index(index) : ::Entitas::Component::Index
      case index
      {% i = 0 %}
      {% for comp in components %}
      when {{i}}, ::{{comp.id}}.class
        Entitas::Component::Index::{{comp.id}}
      {% i = i + 1 %}
      {% end %}
      else
        raise Entitas::Entity::Error::DoesNotHaveComponent.new
      end
    end

    def self.component_index_value(index) : Int32
      case index
      {% i = 0 %}
      {% for comp in components %}
      when Entitas::Component::Index::{{comp.id}}, ::{{comp.id}}.class
        {{i}}
      {% i = i + 1 %}
      {% end %}
      else
        raise Entitas::Entity::Error::DoesNotHaveComponent.new
      end
    end

    def self.component_index_class(index) : Entitas::Component.class
      case index
      {% i = 0 %}
      {% for comp in components %}
      when Entitas::Component::Index::{{comp.id}}, {{i}}
        ::{{comp.id}}
      {% i = i + 1 %}
      {% end %}
      else
        raise Entitas::Entity::Error::DoesNotHaveComponent.new
      end
    end

  end

  macro create_instance_helpers(context)
    def component_index(index) : ::Entitas::Component::Index
      {{context.id}}.component_index(index)
    end

    def component_index_value(index) : Int32
      {{context.id}}.component_index_value(index)
    end

    def component_index_class(index) : Entitas::Component.class
      {{context.id}}.component_index_class(index)
    end
  end
end
