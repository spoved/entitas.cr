class Entitas::Component
  macro inherited

    is_unique

    # When the class is finished search the method names for each setter
    # and populate the initialize arguments.
    macro finished

      \{% begin %}
      \{% comp_methods = {} of StringLiteral => ArrayLiteral(TypeNode) %}
      \{% for meth in @type.methods %}
        \{% if meth.name =~ /^_entitas_set_(.*)$/ %}
          \{% var_name = meth.name.gsub(/^_entitas_set_/, "").id %}
          \{% comp_methods[var_name] = meth %}
        \{% end %}
      \{% end %}

      Entitas::Component.create_comp_module(
        \{{@type.name.id}},
        \{% if comp_methods.empty? %}true\{% else %}false\{% end %},
        \{% if @type.annotation(::Component::Unique) %}true\{% else %}false\{% end %}
      )

      def initialize(
      \{% for var_name, meth in comp_methods %}
        \{% if meth.args[0].default_value %}
          @\{{var_name}} : \{{meth.args[0].restriction}}? = \{{meth.args[0].default_value}},
        \{% else %}
          @\{{var_name}} : \{{meth.args[0].restriction}}? = nil,
        \{% end %}
      \{% end %}
        )
      end


      # Will reset all instance variables to nil or their default value
      def reset
        \{% for var_name, meth in comp_methods %}
          \{% if meth.args[0].default_value %}
            @\{{var_name}} = \{{meth.args[0].default_value}}
          \{% else %}
            @\{{var_name}} = nil
          \{% end %}
        \{% end %}

        self
      end

      def init(**args)
        args.each do |k,v|
          case k
          \{% for var_name, meth in comp_methods %}
          when :\{{var_name}}
            @\{{var_name}} = v.as(\{{meth.args[0].restriction}})
          \{% end %}
          end
        end

        self
      end
      \{% end %}
    end
  end
end
