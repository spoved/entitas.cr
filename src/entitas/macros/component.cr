class Entitas::Component
  macro initializers
    # When the class is finished search the method names for each setter
    # and populate the initialize arguments.
    macro finished
      {% verbatim do %}

        {% comp_variables = {} of StringLiteral => HashLiteral(SymbolLiteral, ArrayLiteral(TypeNode) | TypeNode) %}
        {% for meth in @type.methods %}
          {% if meth.name =~ /^_entitas_set_(.*)$/ %}
            {% var_name = meth.name.gsub(/^_entitas_set_/, "").id %}
            {% comp_variables[var_name] = {} of SymbolLiteral => ArrayLiteral(TypeNode) | TypeNode %}
            {% comp_variables[var_name][:set_method] = meth %}
          {% end %}
        {% end %}

        {% for var_name in comp_variables.keys %}
          {% for meth in @type.methods %}
            {% if meth.name == "_entitas_#{var_name.id}_method" %}
              {% comp_variables[var_name][:constructor] = meth %}
            {% end %}
          {% end %}
        {% end %}

        def initialize(
        {% for var_name in comp_variables.keys %}
          {% meth = comp_variables[var_name][:set_method] %}
          {% if comp_variables[var_name][:constructor] %}
            {{var_name}} : {{meth.args[0].restriction}}? = nil,
          {% elsif meth.args[0].default_value %}
            @{{var_name}} : {{meth.args[0].restriction}}? = {{meth.args[0].default_value}},
          {% else %}
            @{{var_name}} : {{meth.args[0].restriction}}? = nil,
          {% end %}
        {% end %}
          )

          {% for var_name in comp_variables.keys %}
            {% if comp_variables[var_name][:constructor] %}
              if {{var_name}}.nil?
                @{{var_name}} = {{comp_variables[var_name][:constructor].name}}
              else
                @{{var_name}} = {{var_name}}
              end
            {% end %}
          {% end %}
        end


        # Will reset all instance variables to nil or their default value
        def reset
          {% for var_name in comp_variables.keys %}
            {% meth = comp_variables[var_name][:set_method] %}

            {% if comp_variables[var_name][:constructor] %}
              @{{var_name}} = {{comp_variables[var_name][:constructor].name}}
            {% elsif meth.args[0].default_value %}
              @{{var_name}} = {{meth.args[0].default_value}}
            {% else %}
              @{{var_name}} = nil
            {% end %}
          {% end %}

          self
        end

        def init(**args)
          args.each do |k,v|
            case k
            {% for var_name in comp_variables.keys %}
            {% meth = comp_variables[var_name][:set_method] %}
            when :{{var_name}}
              {% if comp_variables[var_name][:constructor] %}
                @{{var_name}} = {{comp_variables[var_name][:constructor].name}}
              {% elsif meth.args[0].default_value %}
                @{{var_name}} = v.as({{meth.args[0].restriction}}) if v.is_a?({{meth.args[0].restriction}})
              {% else %}
                @{{var_name}} = v.as({{meth.args[0].restriction}}?) if v.is_a?({{meth.args[0].restriction}}?)
              {% end %}
            {% end %}
            else
              raise Exception.new("Unknown property #{k} for #{self.class}")
            end
          end

          self
        end

      {% end %}
    end
  end

  macro inherited
    module Helper; end

    Entitas::Component.initializers

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
