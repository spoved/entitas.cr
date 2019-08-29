private macro create_instance_helpers(context)
  def component_index(index) : Entitas::Component::Index
    {{context.id}}.component_index(index)
  end

  def component_index_value(index) : Int32
    {{context.id}}.component_index_value(index)
  end

  def component_index_class(index) : Entitas::Component.class
    {{context.id}}.component_index_class(index)
  end
end

class Entitas::Context(TEntity)
  macro finished
    ### Generate event methods

    private def set_entity_event_hooks(entity)
      {% for meth in @type.methods %}{% if meth.name =~ /^(.*)_event_cache$/ %}
      {% ent_meth_name = meth.name.gsub(/_event_cache$/, "").id %}
      if !{{meth.name.id}}.nil?
        {% if !flag?(:disable_logging) %}logger.debug("Setting {{ent_meth_name.camelcase.id}} hook for #{entity}", self.class){% end %}
        entity.{{ent_meth_name}} &@{{meth.name.id}}.as(Proc(Entitas::Events::{{ent_meth_name.camelcase.id}}, Nil))
      end
      {% end %}{% end %}
    end

    private def set_cache_hooks
      {% for meth in @type.methods %}{% if meth.name =~ /^(.*)_event_cache$/ %}
      {% ent_meth_name = meth.name.gsub(/_event_cache$/, "").id %}
      @{{meth.name.id}} = ->{{ent_meth_name.id}}(Entitas::Events::{{ent_meth_name.camelcase.id}})
      {% end %}{% end %}
    end

  end

  macro finished
    {% verbatim do %}
      {% begin %}

        ### Gather all the contexts
        {% context_map = {} of TypeNode => ArrayLiteral(TypeNode) %}
        {% for obj in Object.all_subclasses %}
          {% if obj.annotation(::Context) %}

            {% contexts = obj.annotation(::Context) %}
            {% for anno in contexts.args %}
              {% context_map[anno] = [] of ArrayLiteral(TypeNode) if context_map[anno].nil? %}
              {% array = context_map[anno] %}
              {% if array == nil %}
                {% context_map[anno] = [obj] %}
              {% else %}
                {% context_map[anno] = array + [obj] %}
              {% end %}
            {% end %}
          {% end %}
        {% end %}

        {% comp_map = {} of TypeNode => HashLiteral(SymbolLiteral, HashLiteral(StringLiteral, ArrayLiteral(TypeNode)) | Bool) %}
        ### Gather all the components and methods
        {% for anno, components in context_map %}
          {% for comp in components %}
            {% comp_methods = {} of StringLiteral => ArrayLiteral(TypeNode) %}
            {% for meth in comp.methods %}
              {% if meth.name =~ /^_entitas_set_(.*)$/ %}
                {% var_name = meth.name.gsub(/^_entitas_set_/, "").id %}
                {% comp_methods[var_name] = meth %}
              {% end %}
            {% end %}
            {% comp_map[comp] = comp_methods %}
          {% end %}
        {% end %}

        ### Cycle through components
        {% for comp, comp_methods in comp_map %}
          {% component_name = comp.name %}

          ### Create a Helper module for each component

          module ::{{component_name.id}}::Helper
            {% is_flag = false %}

            {% comp_methods = {} of StringLiteral => ArrayLiteral(TypeNode) %}
            {% for meth in comp.methods %}
              {% if meth.name =~ /^_entitas_set_(.*)$/ %}
                {% var_name = meth.name.gsub(/^_entitas_set_/, "").id %}
                {% comp_methods[var_name] = meth %}
              {% end %}
            {% end %}

            {% is_flag = comp_methods.empty? ? true : false %}
            {% is_unique = comp.annotation(::Component::Unique) ? true : false %}

            {% comp_map[comp] = {
                 :methods => comp_methods,
                 :flag    => is_flag,
                 :unique  => is_unique,
               } %}

            {% if is_flag %}
              def {{component_name.id.underscore}}?
                self.has_component?(self.component_index_value({{component_name.id}}))
              end

              def is_{{component_name.id.underscore}}=(value : Bool)
                if value
                  self.add_component_{{component_name.id.underscore}}
                else
                  self.del_component_{{component_name.id.underscore}} if self.has_{{component_name.id.underscore}}?
                end
              end
            {% end %}

            # Will replace the current compoent with the provided one
            #
            # ```
            # new_comp = {{component_name}}.new
            # entity.replace_{{component_name.id.underscore}}(new_comp)
            # entity.get_{{component_name.id.underscore}} # => (new_comp)
            # ```
            def replace_{{component_name.id.underscore}}(component : ::{{component_name.id}})
              self.replace_component(component)
            end

            # Alias. See `#replace_{{component_name.id.underscore}}`
            def replace_component_{{component_name.id.underscore}}(component : ::{{component_name.id}})
              self.replace_{{component_name.id.underscore}}(component)
            end

            # Will return true if the entity has an component `{{component_name}}` or false if it does not
            def has_{{component_name.id.underscore}}? : Bool
              self.has_component_{{component_name.id.underscore}}?
            end

            # Will return true if the entity has an component `{{component_name}}` or false if it does not
            def has_component_{{component_name.id.underscore}}? : Bool
              self.has_component?(self.component_index_value(::{{component_name.id}}))
            end

            # Will return the component that is a `{{component_name.id}}` or raise
            def {{component_name.id.underscore}} : {{component_name.id}}
              self.get_component_{{component_name.id.underscore}}
            end

            # Will return the component that is a `{{component_name.id}}` or raise
            def get_component_{{component_name.id.underscore}} : ::{{component_name.id}}
              self.get_component(self.component_index_value(::{{component_name.id}})).as(::{{component_name.id}})
            end

            # Add a `{{component_name.id}}` to the entity. Returns `self` to allow chainables
            # ```
            # entity.add_{{component_name.id.underscore}}
            # ```
            def add_{{component_name.id.underscore}}(**args) : Entitas::Entity
              self.add_component_{{component_name.id.underscore}}(**args)
            end

            # Add a `{{component_name.id}}` to the entity. Returns `self` to allow chainables
            # ```
            # entity.add_component_{{component_name.id.underscore}}
            # ```
            def add_component_{{component_name.id.underscore}}(**args) : Entitas::Entity
              component = self.create_component(::{{component_name.id}}, **args)
              self.add_component(self.component_index_value(::{{component_name.id}}), component)
              self
            end

            # Delete `{{component_name.id}}` from the entity. Returns `self` to allow chainables
            # ```
            # entity.del_{{component_name.id.underscore}}
            # entity.{{component_name.id.underscore}} # => nil
            # ```
            def del_{{component_name.id.underscore}} : Entitas::Entity
              self.del_component_{{component_name.id.underscore}}
              self
            end

            # Delete `{{component_name.id}}` from the entity. Returns `self` to allow chainables
            # ```
            # entity.del_{{component_name.id.underscore}}
            # entity.{{component_name.id.underscore}} # => nil
            # ```
            def del_component_{{component_name.id.underscore}} : Entitas::Entity
              self.remove_component(self.component_index_value(::{{component_name.id}}))
              self
            end

            # See `#del_{{component_name.id.underscore}}`
            def remove_{{component_name.id.underscore}}
              self.del_{{component_name.id.underscore}}
            end

            # See `#del_component_{{component_name.id.underscore}}`
            def remove_component_{{component_name.id.underscore}}
              self.del_component_{{component_name.id.underscore}}
            end

          end
        {% end %}


        {% for context_name, components in context_map %}
          class ::{{context_name.id}}Entity < Entitas::Entity
            {% for comp in components %}
            include ::{{comp.name.id}}::Helper
            {% end %}

            create_instance_helpers(::{{context_name.id}}Context)
          end

          class ::{{context_name.id}}Matcher < Entitas::Matcher
            {% for comp in components %}
            class_getter {{comp.id.underscore}} = Entitas::Matcher.all_of({{comp.id}})
            {% end %}
          end

          # Create a sub class of `Entitas::Context` with the corresponding
          # name and provided components
          #############################################

          class ::{{context_name.id}}Context < Entitas::Context(::{{context_name.id}}Entity)

            enum Index
              {% begin %}
                {% i = 0 %}
                {% for comp in components %}
                  {{comp.id}} = {{i}}
                  {% i = i + 1 %}
                {% end %}
              {% end %}
            end

            CONTEXT_NAME = "{{context_name.id}}Context"

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

            # Unique components
            UNIQUE_COMPONENTS = [
            {% for comp in components %}
              {% if comp_map[comp][:unique] %}
                ::{{comp.name.id}},
              {% end %}
            {% end %}
            ] of Entitas::Component.class

            # The total number of `Entitas::Component` subclases in this context
            TOTAL_COMPONENTS = {{components.size}}

            COMPONENT_NAMES = COMPONENT_TO_INDEX_MAP.keys.map &.to_s
            COMPONENT_KLASSES = COMPONENT_TO_INDEX_MAP.keys.as(Entitas::Component::KlassList)

            # The total amount of components an entity can possibly have.
            def total_components : Int32
              TOTAL_COMPONENTS
            end

            def self.total_components : Int32
              TOTAL_COMPONENTS
            end

            private def create_default_context_info : Entitas::Context::Info
              {% if !flag?(:disable_logging) %}logger.debug("Creating default context", CONTEXT_NAME){% end %}

              @component_names_cache.clear
              prefix = "Index "
              total_components.times do |i|
                @component_names_cache << prefix + i.to_s
              end

              Entitas::Context::Info.new(
                CONTEXT_NAME,
                component_names_cache,
                COMPONENT_KLASSES
              )
            end

            # Default `#entity_factory` for `{{context_name.id}}Context`
            #
            # ```
            # ctx = {{context_name.id}}Context.new
            # ctx.entity_factory # => {{context_name.id}}Entity
            # ```
            def entity_factory : ::{{context_name.id}}Entity
              ::{{context_name.id}}Entity.new(
                creation_index,
                total_components,
                component_pools,
              )
            end

            def self.component_index(index) : Entitas::Component::Index
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

            create_instance_helpers(::{{context_name.id}}Context)

            # For each unique component create functions to add, edit and remove
            # entities at the context level
            {% for comp in components %}
              {% if comp_map[comp][:unique] %}

                # def has_unique_component_already?(comp : Entitas::Component.class)
                #   case comp
                #   {% for component in components %}
                #   when ::{{component.id}}.class
                #       self.{{component.id.underscore.id}}?
                #   {% end %}
                #   else
                #     false
                #   end
                # end

                def {{comp.id.underscore.id}}_entity : Entitas::Entity?
                  self.get_group(::{{context_name.id}}Matcher.{{comp.id.underscore.id}}).get_single_entity
                end

                def {{comp.id.underscore.id}} : {{comp.id}}
                  entity = {{comp.id.underscore.id}}_entity
                  raise Error.new "No {{comp.id}} has been set for #{self}" if entity.nil?
                  entity.{{comp.id.underscore.id}}
                end

                def {{comp.id.underscore.id}}? : Bool
                  !{{comp.id.underscore.id}}_entity.nil?
                end

                def set_{{comp.id.underscore.id}}(value : {{comp.id}})
                  if {{comp.id.underscore.id}}?
                    raise Error.new "Could not set {{comp.id}}!\n" \
                      "#{self} already has an entity with ScoreComponent!" \
                      "You should check if the context already has a " \
                      "{{comp.id.underscore.id}} Entity before setting " \
                      "it or use context.replace_{{comp.id.underscore.id}}."
                  end
                  entity = self.create_entity
                  entity.add_component(value)
                  entity
                end

                def {{comp.id.underscore.id}}=(value : {{comp.id}}) : Entitas::Entity
                  set_{{comp.id.underscore.id}}(value)
                end

                def replace_{{comp.id.underscore.id}}(value : {{comp.id}})
                  entity = self.{{comp.id.underscore.id}}_entity
                  if entity.nil?
                    entity = set_{{comp.id.underscore.id}}(value)
                  else
                    entity.replace_component(value)
                  end
                  entity
                end
              {% end %}
            {% end %}
          end
        {% end %}
      {% end %}
    {% end %}
  end
end
