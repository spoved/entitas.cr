class ::Entitas::Contexts
  # :nodoc:
  macro generate_sub_context_methods
    class ::Entitas::Contexts
      {% contexts = {} of TypeString => TypeNode %}

      {% for context in Entitas::Context.all_subclasses %}
        {% context_name = context.name.gsub(/Context/, "").underscore %}
        {% contexts[context_name] = context %}
      {% end %}

      {% for context_name, context in contexts %}
      property {{context_name}} : ::{{context.id}} = ::{{context.id}}.new
      {% end %}

      # Returns an array containing each available context
      def all_contexts : Array(Entitas::IContext)
        @_all_contexts ||= [
          {% for context_name, context in contexts %}
            self.{{context_name}},
          {% end %}
        ] of Entitas::IContext
      end
    end
  end
end
