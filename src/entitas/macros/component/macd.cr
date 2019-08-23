class Entitas::Component
  macro inject_component_macd(klass, component_name)
    class {{klass.id}}
      def replace_{{component_name.id.underscore}}(component : {{component_name.id}})
        self.replace_component(component)
      end

      def replace_component_{{component_name.id.underscore}}(component : {{component_name.id}})
        self.replace_{{component_name.id.underscore}}(component)
      end

      def has_{{component_name.id.underscore}}?
        self.has_component_{{component_name.id.underscore}}?
      end

      def has_component_{{component_name.id.underscore}}?
        self.has_component?(self.component_index_value({{component_name.id}}))
      end

      # Will return the component that is a `{{component_name.id}}` or raise
      def {{component_name.id.underscore}} : {{component_name.id}}
        self.get_component_{{component_name.id.underscore}}
      end

      def get_component_{{component_name.id.underscore}} : {{component_name.id}}
        self.get_component(self.component_index_value({{component_name.id}})).as({{component_name.id}})
      end

      # Add a `{{component_name.id}}` to the entity. Returns `self` to allow chainables
      # ```
      # entity.add_{{component_name.id.underscore}}
      # ```
      def add_{{component_name.id.underscore}}(**args) : ::Entitas::Entity
        self.add_component_{{component_name.id.underscore}}(**args)
      end

      # Add a `{{component_name.id}}` to the entity. Returns `self` to allow chainables
      # ```
      # entity.add_component_{{component_name.id.underscore}}
      # ```
      def add_component_{{component_name.id.underscore}}(**args) : ::Entitas::Entity
        component = self.create_component({{component_name.id}}, **args)
        self.add_component(self.component_index_value({{component_name.id}}), component)
        self
      end

      # Delete `{{component_name.id}}` from the entity. Returns `self` to allow chainables
      # ```
      # entity.del_{{component_name.id.underscore}}
      # entity.{{component_name.id.underscore}} # => nil
      # ```
      def del_{{component_name.id.underscore}} : ::Entitas::Entity
        self.del_component_{{component_name.id.underscore}}
        self
      end

      # Delete `{{component_name.id}}` from the entity. Returns `self` to allow chainables
      # ```
      # entity.del_{{component_name.id.underscore}}
      # entity.{{component_name.id.underscore}} # => nil
      # ```
      def del_component_{{component_name.id.underscore}} : ::Entitas::Entity
        self.remove_component(self.component_index_value({{component_name.id}}))
        self
      end

      # See `del_{{component_name.id.underscore}}`
      def remove_{{component_name.id.underscore}}
        self.del_{{component_name.id.underscore}}
      end

      # See `del_component_{{component_name.id.underscore}}`
      def remove_component_{{component_name.id.underscore}}
        self.del_component_{{component_name.id.underscore}}
      end
    end
  end
end
