macro create_entity_for_context(context_name)
  class ::{{context_name.id}}Entity < ::Entitas::Entity
    def klass_to_index(klass) : Int32
      raise Error::DoesNotHaveComponent.new unless ::{{context_name.id}}Context::COMPONENT_TO_INDEX_MAP[klass]?
      ::{{context_name.id}}Context::COMPONENT_TO_INDEX_MAP[klass].value
    end

    def self.index(i : ::Entitas::Component::Index) : ::{{context_name.id}}Context::Index
      klass = ::Entitas::Component::INDEX_TO_COMPONENT_MAP[i]
      ::{{context_name.id}}Context::COMPONENT_TO_INDEX_MAP[klass]
    rescue KeyError
      raise Error::DoesNotHaveComponent.new
    end

    def index(i : ::Entitas::Component::Index) : ::{{context_name.id}}Context::Index
      self.class.index(i)
    end

    def self.index_class(i : ::Entitas::Component::Index)
      ::{{context_name.id}}Context::INDEX_TO_COMPONENT_MAP[self.index(i)]
    end

    def index_class(i : ::Entitas::Component::Index)
      ::{{context_name.id}}Entity.index_class(i)
    end

    def self.index_value(i : ::Entitas::Component::Index) : Int32
      self.index(i).value
    end

    def index_value(i : ::Entitas::Component::Index) : Int32
      self.index(i).value
    end
  end
end
