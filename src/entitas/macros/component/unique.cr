class Entitas::Component
  macro inherited

    # If the component has the unique annotation,
    #   set the class method to `true`
    # The framework will make sure that only one instance of a unique component can be present in your context
    {% if @type.annotation(::Component::Unique) %}
      # Will return true if the class is a unique component for a context
      def is_unique? : Bool
        true
      end

      # ditto
      def self.is_unique? : Bool
        true
      end
    {% else %}
      # Will return true if the class is a unique component for a context
      def is_unique? : Bool
        false
      end

      # ditto
      def self.is_unique? : Bool
        false
      end
    {% end %}
  end
end
