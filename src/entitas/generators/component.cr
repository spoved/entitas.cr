class Entitas::Component
  # :nodoc:
  macro check_components
    {% begin %}

      {% components = [] of TypeNode %}
      {% comp_map = {} of TypeNode => HashLiteral(SymbolLiteral, HashLiteral(StringLiteral, ArrayLiteral(TypeNode)) | Bool) %}

      ### Gather all the components
      {% for obj in Object.all_subclasses.sort_by(&.name) %}
        {% if obj.annotation(::Context) %}
          # Exclude components that have already been generated
          {% if !obj.constants.find(&.stringify.==("Helper")) %}
            {% components << obj %}
          {% end %}
        {% end %}
      {% end %} # end for obj in Object.all_subclasses.sort_by(&.name)
      {% components = components.uniq %}

      ### Gather all the components and methods
      {% for comp in components %}
        {% comp_methods = {} of StringLiteral => ArrayLiteral(TypeNode) %}
        {% for meth in comp.methods %}
          {% if meth.name =~ /^_entitas_set_(.*)$/ %}
            {% var_name = meth.name.gsub(/^_entitas_set_/, "").id %}
            {% comp_methods[var_name] = meth %}
          {% end %}
        {% end %}
        {% component_name = comp.name.gsub(/.*::/, "") %}
        {% component_meth_name = component_name.underscore %}
        {% comp_map[comp] = {
             :name        => component_name,
             :methods     => comp_methods,
             :index_alias => comp.id.gsub(/::/, "").underscore.upcase,
             :meth_name   => component_meth_name.id,
             :contexts    => [] of ArrayLiteral(TypeNode),
             :flag        => comp_methods.empty? ? true : false,
             :unique      => comp.annotation(::Component::Unique) ? true : false,
           } %}
      {% end %}

      ### Cycle through components and inject `Entitas::IComponent` and make helper modules
      {% for comp in components %}
        {% if comp.constants.find(&.stringify.==("Helper")) %}
          {% raise "#{comp.id} has already been generated!" %}
        {% else %}

          {% if flag?(:entitas_debug_generator) %}{% puts "## Generating component #{comp.id}" %}{% end %}
          {% component_name = comp.name.gsub(/.*::/, "") %}
          {% component_meth_name = component_name.underscore %}

          ### Check to see if the component is a sub-class of ::Entitas::Component
          class ::{{comp.id}}
            {% if !comp.ancestors.includes?(Entitas::IComponent) %}
            {% if flag?(:entitas_debug_generator) %}{% puts "* #{comp.id} was NOT inherited" %}{% end %}
            include Entitas::IComponent
            {% end %} # end if !comp.ancestors.includes?(Entitas::IComponent)

            {{comp.id}}.setup_base_comp
          end

          ### Create a Helper module for the component

          module ::{{comp.id}}::Helper
            {% is_flag = false %}

            {% comp_methods = {} of StringLiteral => ArrayLiteral(TypeNode) %}
            {% for meth in comp.methods %}
              {% if meth.name =~ /^_entitas_set_(.*)$/ %}
                {% var_name = meth.name.gsub(/^_entitas_set_/, "").id %}
                {% comp_methods[var_name] = meth %}
              {% end %}
            {% end %}

            {% if comp_map[comp][:flag] %}
              def {{component_meth_name}}?
                self.has_component?(self.component_index_value({{component_name.id}}))
              end

              def {{component_meth_name}}=(value : Bool)
                if value
                  self.add_component_{{component_meth_name}}
                else
                  self.del_component_{{component_meth_name}} if self.has_{{component_meth_name}}?
                end
              end
            {% end %}

            {% if comp_map[comp][:methods].size == 1 %}
              {% n = comp_map[comp][:methods].keys.first %}
              # Will replace the current component with the new one
              # generated from the provided arguments
              #
              # ```
              # entity.replace_{{component_meth_name}}(value: 1)
              # entity.get_{{component_meth_name}} # => (new_comp)
              # ```
              #
              # or
              #
              # ```
              # entity.replace_{{component_meth_name}}(1)
              # entity.get_{{component_meth_name}} # => (new_comp)
              # ```
              def replace_{{component_meth_name}}({{n.id}} : {{comp_map[comp][:methods][n].args[0].restriction.id}})
                component = self.create_component(::{{comp.id}}, {{n.id}}: {{n.id}})
                self.replace_component(self.component_index_value(::{{comp.id}}), component)
              end
            {% elsif comp_map[comp][:methods].size > 1 %}
              # Will replace the current component with the new one
              # generated from the provided arguments
              #
              # ```
              # entity.replace_{{component_meth_name}}
              # entity.get_{{component_meth_name}} # => (new_comp)
              # ```
              def replace_{{component_meth_name}}(**args)
                component = self.create_component(::{{comp.id}}, **args)
                self.replace_component(self.component_index_value(::{{comp.id}}), component)
              end
            {% else %}
              # Will replace the current component with the new one
              # generated from the provided arguments
              #
              # ```
              # entity.replace_{{component_meth_name}}
              # entity.get_{{component_meth_name}} # => (new_comp)
              # ```
              def replace_{{component_meth_name}}
                component = self.create_component(::{{comp.id}})
                self.replace_component(self.component_index_value(::{{comp.id}}), component)
              end
            {% end %}

            # Will replace the current component with the new one provided
            #
            # ```
            # entity.replace_component_{{component_meth_name}}(new_comp)
            # entity.get_{{component_meth_name}} # => (new_comp)
            # ```
            def replace_{{component_meth_name}}(component : ::{{comp.id}})
              self.replace_component_{{component_meth_name}}(component)
            end

            # Append. Alias for `replace_{{component_meth_name}}`
            def replace_component_{{component_meth_name}}(component : ::{{comp.id}})
              self.replace_component(self.component_index_value(::{{comp.id}}), component)
            end

            # Will replace the current component with the new one
            # generated from the provided arguments
            #
            # ```
            # entity.replace_{{component_meth_name}}
            # entity.get_{{component_meth_name}} # => (new_comp)
            # ```
            def replace_component_{{component_meth_name}}(**args)
              component = self.create_component(::{{comp.id}}, **args)
              self.replace_component(self.component_index_value(::{{comp.id}}), component)
            end

            # Will return true if the entity has an component `{{comp.id}}` or false if it does not
            def has_{{component_meth_name}}? : Bool
              self.has_component_{{component_meth_name}}?
            end

            # Alias. See `#has_{{component_meth_name}}?`
            def {{component_meth_name}}? : Bool
              self.has_component_{{component_meth_name}}?
            end

            # Will return true if the entity has an component `{{comp.id}}` or false if it does not
            def has_component_{{component_meth_name}}? : Bool
              self.has_component?(self.component_index_value(::{{comp.id}}))
            end

            # Will return the component that is a `{{comp.id}}` or raise
            def {{component_meth_name}} : ::{{comp.id}}
              self.get_component_{{component_meth_name}}
            end

            # Will return the component that is a `{{comp.id}}` or raise
            def get_component_{{component_meth_name}} : ::{{comp.id}}
              self.get_component(self.component_index_value(::{{comp.id}})).as(::{{comp.id}})
            end

            {% if comp_map[comp][:methods].size == 1 %}
              {% n = comp_map[comp][:methods].keys.first %}
              {% meth_n = comp_map[comp][:methods][n].args[0] %}
              # Add a `{{comp.id}}` to the entity. Returns `self` to allow chainables
              #
              # ```
              # entity.add_{{component_meth_name}}(1)
              # ```
              def add_{{component_meth_name}}(
                  {{n.id}} : {{meth_n.restriction.id}} {% if meth_n.default_value %}= {{meth_n.default_value}}{% end %}
                ) : Entitas::Entity
                {% if flag?(:entitas_enable_logging) %}Log.debug { "add_{{component_meth_name}} - {{n.id}}: #{{{n.id}}}" }{% end %}
                self.add_component_{{component_meth_name}}({{n.id}}: {{n.id}})
              end
            {% elsif comp_map[comp][:methods].size > 1 %}
              # Add a `{{comp.id}}` to the entity. Returns `self` to allow chainables
              #
              # ```
              # entity.add_{{component_meth_name}}
              # ```
              def add_{{component_meth_name}}(**args) : Entitas::Entity
                self.add_component_{{component_meth_name}}(**args)
              end
            {% else %}
              # Add a `{{comp.id}}` to the entity. Returns `self` to allow chainables
              #
              # ```
              # entity.add_{{component_meth_name}}
              # ```
              def add_{{component_meth_name}} : Entitas::Entity
                self.add_component_{{component_meth_name}}
              end
            {% end %}

            # Add a `{{comp.id}}` to the entity. Returns `self` to allow chainables
            #
            # ```
            # entity.add_component_{{component_meth_name}}
            # ```
            def add_component_{{component_meth_name}} : Entitas::Entity
              component = self.create_component(::{{comp.id}})
              self.add_component(self.component_index_value(::{{comp.id}}), component)
              self
            end

            # Add a `{{comp.id}}` to the entity. Returns `self` to allow chainables
            #
            # ```
            # entity.add_component_{{component_meth_name}}
            # ```
            def add_component_{{component_meth_name}}(**args) : Entitas::Entity
              component = self.create_component(::{{comp.id}}, **args)
              self.add_component(self.component_index_value(::{{comp.id}}), component)
              self
            end

            # Delete `{{comp.id}}` from the entity. Returns `self` to allow chainables
            #
            # ```
            # entity.del_{{component_meth_name}}
            # entity.{{component_meth_name}} # => nil
            # ```
            def del_{{component_meth_name}} : Entitas::Entity
              self.del_component_{{component_meth_name}}
              self
            end

            # Delete `{{comp.id}}` from the entity. Returns `self` to allow chainables
            #
            # ```
            # entity.del_{{component_meth_name}}
            # entity.{{component_meth_name}} # => nil
            # ```
            def del_component_{{component_meth_name}} : Entitas::Entity
              self.remove_component(self.component_index_value(::{{comp.id}}))
              self
            end

            # Append. Alias for `del_{{component_meth_name}}`
            def remove_{{component_meth_name}}
              self.del_{{component_meth_name}}
            end

            # Append. Alias for `del_component_{{component_meth_name}}`
            def remove_component_{{component_meth_name}}
              self.del_component_{{component_meth_name}}
            end
          end
        {% end %}
      {% end %} # end for comp, comp_methods in comp_map
    {% end %} # end begin
  end
end
