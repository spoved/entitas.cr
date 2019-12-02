private macro create_instance_helpers(context)
  def component_index(index) : Entitas::Component::Index
    {{context.id}}.component_index(index)
  end

  def component_index_value(index) : Int32
    {{context.id}}.component_index_value(index)
  end

  def component_index_class(index) : Entitas::Component::ComponentTypes
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
        {% if flag?(:entitas_enable_logging) %}logger.debug("Setting {{ent_meth_name.camelcase.id}} hook for #{entity}", self.class){% end %}
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
        {% context_map = {} of TypeNode => ArrayLiteral(TypeNode) %}
        {% events_map = {} of TypeNode => ArrayLiteral(TypeNode) %}
        {% comp_map = {} of TypeNode => HashLiteral(SymbolLiteral, HashLiteral(StringLiteral, ArrayLiteral(TypeNode)) | Bool) %}

        {% for obj in Object.all_subclasses.sort_by { |a| a.name } %}
          ### Gather all the contexts
          {% if obj.annotation(::Context) %}
            {% contexts = obj.annotations(::Context) %}
            {% for context in contexts %}
              {% for anno in context.args %}
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

          ### Gather all the events
          {% if obj.annotation(::Entitas::Event) %}
            {% events_map[obj] = [] of ArrayLiteral(Annotation) if events_map[obj].nil? %}
            {% events_map[obj] = obj.annotations(::Entitas::Event) %}
          {% end %}

        {% end %}

        ### Gather all the components and methods
        {% for anno, components in context_map %}
          {% components = components.uniq %}
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

        class ::Entitas::Component
          alias ComponentTypes = Union(Entitas::Component.class, {{*comp_map.keys.map { |c| c.name + ".class" }}})

          enum Index
            {% begin %}
              {% i = 0 %}
              {% for comp in comp_map.keys %}
                {{comp.name.gsub(/.*::/, "").id}} = {{i}}
                {% i = i + 1 %}
              {% end %}
            {% end %}
          end

          # A hash to map of enum `Index` to class of `Component`
          INDEX_TO_COMPONENT_MAP = {
            {% for comp in comp_map.keys %}
              Index::{{comp.name.gsub(/.*::/, "").id}} => ::{{comp.id}},
            {% end %}
          } of Index => Entitas::Component::ComponentTypes

          # A hash to map of class of `Component` to enum `Index`
          COMPONENT_TO_INDEX_MAP = {
            {% for comp in comp_map.keys %}
              ::{{comp.id}} => Index::{{comp.name.gsub(/.*::/, "").id}},
            {% end %}
          } of Entitas::Component::ComponentTypes => Index

          COMPONENT_NAMES = COMPONENT_TO_INDEX_MAP.keys.map &.to_s
          COMPONENT_KLASSES = [
            {% for comp in comp_map.keys %}
              ::{{comp.id}},
            {% end %}
          ] of Entitas::Component::ComponentTypes

          # The total number of componets
          TOTAL_COMPONENTS = {{comp_map.size}}

          # The total amount of components an entity can possibly have.
          def total_components : Int32
            TOTAL_COMPONENTS
          end

          def self.total_components : Int32
            TOTAL_COMPONENTS
          end

          {% i = 0 %}
          {% for comp, comp_methods in comp_map %}
            {% component_name = comp.name.gsub(/.*::/, "") %}

            class ::{{comp.id}}

              INDEX = Entitas::Component::Index::{{component_name.id}}
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
          {% end %}

        end

        ### Cycle through components and inject `Entitas::IComponent` and make helper modules
        {% for comp, comp_methods in comp_map %}
          {% component_name = comp.name.gsub(/.*::/, "") %}
          {% component_meth_name = component_name.underscore %}

          ### Check to see if the component is a subklass of ::Entitas::Component

          {% if !comp.ancestors.includes?(Entitas::IComponent) %}
            class ::{{comp.id}}
              include Entitas::IComponent

              def is_unique? : Bool
                {% if comp.annotation(::Component::Unique) %}
                true
                {% else %}
                false
                {% end %}
              end
            end
          {% end %}

          ### Create a Helper module for each component

          module ::{{comp.id}}::Helper
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
                 :methods     => comp_methods,
                 :flag        => is_flag,
                 :unique      => is_unique,
                 :index_alias => comp.id.gsub(/::/, "").underscore.upcase,
                 :meth_name   => component_meth_name.id,
               } %}

            {% if is_flag %}
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

              @[::Component::Flag]
              class ::{{comp.id}}; end
            {% end %}

            # Will replace the current component with the provided one
            #
            # ```
            # new_comp = ::{{comp.id}}
            # entity.replace_{{component_meth_name}}(new_comp)
            # entity.get_{{component_meth_name}} # => (new_comp)
            # ```
            def replace_{{component_meth_name}}(component : ::{{comp.id}})
              self.replace_component(component)
            end

            # Append. Alias for `replace_{{component_meth_name}}`
            def replace_component_{{component_meth_name}}(component : ::{{comp.id}})
              self.replace_{{component_meth_name}}(component)
            end

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
            def replace_{{component_meth_name}}(value)
              component = self.create_component(::{{comp.id}}, value: value)
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

            # Add a `{{comp.id}}` to the entity. Returns `self` to allow chainables
            #
            # ```
            # entity.add_{{component_meth_name}}
            # ```
            def add_{{component_meth_name}}(**args) : Entitas::Entity
              self.add_component_{{component_meth_name}}(**args)
            end

            # Add a `{{comp.id}}` to the entity. Returns `self` to allow chainables
            #
            # ```
            # entity.add_{{component_meth_name}}(value: 1)
            # ```
            #
            # or
            #
            # ```
            # entity.add_{{component_meth_name}}(1)
            # ```
            def add_{{component_meth_name}}(value) : Entitas::Entity
              self.add_component_{{component_meth_name}}(value: value)
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

        # Create entity, matcher, and context

        {% for context_name, components in context_map %}
          {% components = components.uniq %}

          # `Entitas::Entity` for the `{{context_name.id}}Context`
          class ::{{context_name.id}}Entity < Entitas::Entity
            {% for comp in components %}
            include ::{{comp.name.id}}::Helper
            {% end %}

            create_instance_helpers(::{{context_name.id}}Context)
          end

          class ::{{context_name.id}}Matcher < Entitas::Matcher
            {% for comp in components %}
            class_getter {{comp.name.gsub(/.*::/, "").underscore.id}} = Entitas::Matcher.all_of({{comp.id}})
            {% end %}
          end

          # Create a sub class of `Entitas::Context` with the corresponding
          # name and provided components
          #############################################


          # Sub context {{context_name.id}}
          class ::{{context_name.id}}Context < Entitas::Context(::{{context_name.id}}Entity)

            def to_json(json)
              json.object do
                json.field "name", CONTEXT_NAME
                json.field "size", self.size
                json.field "entities", get_entities
                json.field "components", COMPONENT_NAMES
                json.field "creation_index", creation_index
                json.field "info", context_info
                json.field "reusable_entities", reusable_entities.size
                json.field "retained_entities", retained_entities.size

                json.field "component_pools" do
                  json.object do
                    component_pools.each_with_index do |pool, i|
                      json.field i, pool.size
                    end
                  end
                end

                json.field "groups_for_index", groups_for_index
              end
            end

            enum Index
              {% begin %}
                {% i = 0 %}
                {% for comp in components %}
                  {{comp.name.gsub(/.*::/, "").id}} = {{i}}
                  {% i = i + 1 %}
                {% end %}
              {% end %}
            end

            CONTEXT_NAME = "{{context_name.id}}Context"

            # A hash to map of enum `Index` to class of `Component`
            INDEX_TO_COMPONENT_MAP = {
              {% for comp in components %}
                Index::{{comp.name.gsub(/.*::/, "").id}} => ::{{comp.id}},
              {% end %}
            } of Index => Entitas::Component::ComponentTypes

            # A hash to map of class of `Component` to enum `Index`
            COMPONENT_TO_INDEX_MAP = {
              {% for comp in components %}
                ::{{comp.id}} => Index::{{comp.name.gsub(/.*::/, "").id}},
              {% end %}
            } of Entitas::Component::ComponentTypes => Index

            # Unique components
            UNIQUE_COMPONENTS = [
            {% for comp in components %}
              {% if comp_map[comp][:unique] %}
                ::{{comp.name.id}},
              {% end %}
            {% end %}
            ] of Entitas::Component::ComponentTypes

            # The total number of `Entitas::Component` subclases in this context
            TOTAL_COMPONENTS = {{components.size}}

            COMPONENT_NAMES = [
              {% for comp in components %}
                {{comp.id.stringify}},
              {% end %}
            ]
            COMPONENT_KLASSES = [
              {% for comp in components %}
                ::{{comp.id}},
              {% end %}
            ] of Entitas::Component::ComponentTypes

            # The total amount of components an entity can possibly have.
            def total_components : Int32
              TOTAL_COMPONENTS
            end

            # ditto
            def self.total_components : Int32
              TOTAL_COMPONENTS
            end

            private def create_default_context_info : Entitas::Context::Info
              {% if flag?(:entitas_enable_logging) %}logger.debug("Creating default context", CONTEXT_NAME){% end %}

              @component_names_cache.clear
              @component_names_cache = COMPONENT_NAMES

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

            # Will return true if the context contains the component,
            # false if it does not.
            def self.has_component?(index) : Bool
              case index
              {% i = 0 %}
              {% for comp in components %}
              when {{i}}, ::{{comp.id}}.class, Entitas::Component::Index::{{comp.name.gsub(/.*::/, "").id}}
                true
              {% i = i + 1 %}
              {% end %}
              else
                false
              end
            end

            # Will return the `Entitas::Matcher` class for the context
            def self.matcher : ::{{context_name.id}}Matcher
              ::{{context_name.id}}Matcher.new
            end

            # Will return the `Entitas::Component::Index` for the provided index
            def self.component_index(index) : Entitas::Component::Index
              case index
              {% i = 0 %}
              {% for comp in components %}
              when {{i}}, ::{{comp.id}}.class
                Entitas::Component::Index::{{comp.name.gsub(/.*::/, "").id}}
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
              when Entitas::Component::Index::{{comp.name.gsub(/.*::/, "").id}}, ::{{comp.id}}.class
                {{i}}
              {% i = i + 1 %}
              {% end %}
              else
                raise Entitas::Entity::Error::DoesNotHaveComponent.new
              end
            end

            def self.component_index_class(index) : Entitas::Component::ComponentTypes
              case index
              {% i = 0 %}
              {% for comp in components %}
              when Entitas::Component::Index::{{comp.name.gsub(/.*::/, "").id}}, {{i}}
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
                {% comp_name = comp_map[comp][:meth_name] %}

                def {{comp_name.id}}_entity : Entitas::Entity?
                  self.get_group(::{{context_name.id}}Matcher.{{comp_name.id}}).get_single_entity
                end

                def {{comp_name.id}} : {{comp.id}}
                  entity = {{comp_name.id}}_entity
                  raise Error.new "No {{comp.id}} has been set for #{self}" if entity.nil?
                  entity.{{comp_name.id}}
                end

                {% if comp_map[comp][:flag] %}

                  def {{comp_name.id}}=(value : Bool)
                    if value == true && {{comp_name.id}}_entity.nil?
                      self.create_entity.add_{{comp_name.id}}
                    elsif value == true && !{{comp_name.id}}_entity.nil?
                      # Do nothing
                    elsif value == false && {{comp_name.id}}_entity.nil?
                      # DO nothing
                    elsif value == false && !{{comp_name.id}}_entity.nil?
                      {{comp_name.id}}_entity.as({{context_name.id}}Entity).del_{{comp_name.id}}
                    end
                  end

                  # Will check to see if there is a `{{context_name.id}}Entity` with
                  # a `{{comp.id}}` component
                  def {{comp_name.id}}? : Bool
                    !{{comp_name.id}}_entity.nil?
                  end

                {% else %}

                # Will check to see if there is a `{{context_name.id}}Entity` with
                # a `{{comp.id}}` component
                def has_{{comp_name.id}}? : Bool
                  !{{comp_name.id}}_entity.nil?
                end

                # Alias. See `#has_{{comp_name.id}}?`
                def {{comp_name.id}}? : Bool
                  !{{comp_name.id}}_entity.nil?
                end

                # Will create a new `{{context_name.id}}Entity` and set the `{{comp.id}}` to the
                # provided value. If an entity already exists with the unique component,
                # a `Error` will be raised. The created `{{context_name.id}}Entity` will be returned
                #
                # ```
                # context.set_{{comp_name.id}}({{comp.id}}.new) # => {{context_name.id}}Entity
                # ```
                def set_{{comp_name.id}}(value : {{comp.id}}) : {{context_name.id}}Entity
                  if has_{{comp_name.id}}?
                    raise Error.new "Could not set {{comp.id}}!\n" \
                      "#{self} already has an entity with {{comp.id}}!" \
                      "You should check if the context already has a " \
                      "{{comp_name.id}} Entity before setting " \
                      "it or use context.replace_{{comp_name.id}}."
                  end
                  entity = self.create_entity
                  entity.add_component(value)
                  entity
                end

                def {{comp_name.id}}=(value : {{comp.id}}) : Entitas::Entity
                  set_{{comp_name.id}}(value)
                end

                # Replaces the `{{comp.id}}` on an existing `{{context_name.id}}Entity`.
                # If no existing `{{context_name.id}}Entity` with a `{{comp.id}}` exists,
                # one will be created. Will return the `{{context_name.id}}Entity` with the
                # replaced component.
                def replace_{{comp_name.id}}(value : {{comp.id}}) : {{context_name.id}}Entity
                  entity = self.{{comp_name.id}}_entity
                  if entity.nil?
                    entity = set_{{comp_name.id}}(value)
                  else
                    entity.replace_component(value)
                  end
                  entity
                end

                # Replaces the `{{comp.id}}` on an existing `{{context_name.id}}Entity`.
                # If no existing `{{context_name.id}}Entity` with a `{{comp.id}}` exists,
                # one will be created. Will return the `{{context_name.id}}Entity` with the
                # replaced component.
                def replace_{{comp_name.id}}(**args) : {{context_name.id}}Entity
                  entity = self.{{comp_name.id}}_entity
                  if entity.nil?
                    entity = self.create_entity.add_{{comp_name.id}}(**args)
                  else
                    entity.replace_{{comp_name.id}}(**args)
                  end
                  entity
                end

                {% end %}

              {% end %}
            {% end %}
          end

          ### Create event interfaces for each component with an event
          {% for comp in components %}
            {% is_flag = comp.annotation(::Component::Flag) ? true : false %}
            {% is_unique = comp.annotation(::Component::Unique) ? true : false %}
            {% if events_map[comp] %}
              {% for event in events_map[comp] %}
                {% event_target = event.args[0] %}
                {% event_type = event.args[1] %}
                {% event_priority = event.named_args[:priority] %}

                component_event_system({{context_name.id}}, {{comp.id}}, {{event_target.id}}, {{event_type.id}}, {{event_priority.id}}, {{is_flag.id}})
              {% end %}
            {% end %}
          {% end %}

        {% end %}

        #TODO: Create any entity indexes

        {% entity_indicies = [] of HashLiteral(SymbolLiteral, HashLiteral(StringLiteral, ArrayLiteral(TypeNode)) | Bool) %}

        {% for const in ::Entitas::Contexts.constants %}
          {% if const =~ /ENTITY_INDICES/ %}
            {% parts = const.split("_ENTITY_INDICES_") %}
            {% prop = parts.last.downcase %}
            # Cycle through each component to find the matching alias
            {% for comp in comp_map.keys %}
              {% if comp_map[comp][:index_alias] == parts[0] %}

                # Cycle through each context, to add the entity index to it
                {% for context_name, components in context_map %}
                  {% if components.includes?(comp) %}
                    {% types = comp.methods.find { |m| m.name == prop }.return_type %}
                    {% if types.is_a?(Union) %}
                      {% types = types.types.reject { |t| "#{t}" == "::Nil" }.join(" | ").id %}
                    {% end %}

                    {%
                      entity_indicies.push({
                        index_alias:   parts[0],
                        const:         const,
                        comp:          comp,
                        comp_meth:     comp_map[comp][:meth_name],
                        prop:          prop,
                        prop_type:     types,
                        context_name:  context_name,
                        contexts_meth: "#{context_name}".underscore.downcase,
                      })
                    %}
                  {% end %} # end {if components.includes?(comp)}

                {% end %} # end {for context_name, components in context_map}
              {% end %} # end {for comp in comp_map.keys}
            {% end %} # end {if const =~ /ENTITY_INDICES/}
          {% end %} # if const =~ /ENTITY_INDICES/
        {% end %} # for const in ::Entitas::Contexts.constants

        class ::Entitas::Contexts

          # Will be called after initialization to intitialze each `EntityIndex` for
          # all of the contexts.
          @[::Entitas::PostConstructor]
          def initialize_entity_indices
            {% for index in entity_indicies %}

            {{index[:contexts_meth].id}}.add_entity_index(
              ::Entitas::EntityIndex({{index[:context_name].id}}Entity, {{index[:prop_type].id}}).new(
                ::Contexts::{{index[:const].id}},

                {{index[:contexts_meth].id}}.get_group(
                  {{index[:context_name].id}}Matcher.{{index[:comp_meth].id}}
                ),
                ->(entity : {{index[:context_name].id}}Entity, component : Entitas::IComponent?) {
                  if component.nil?
                    entity.get_component_{{index[:comp_meth].id}}.{{index[:prop].id}}.as({{index[:prop_type].id}})
                  else
                    component.as({{index[:comp]}}).{{index[:prop].id}}.as({{index[:prop_type].id}})
                  end
                }

              )
            )
            {% end %} # end for index in entity_indicies
          end

          module Extensions
            {% for index in entity_indicies %}

              def get_entities_with_{{ index[:prop].id }}(context : Entitas::IContext, value : {{index[:prop_type].id}})
                context.get_entity_index(::Contexts::{{index[:const].id}}).get_entities(value)
              end
            {% end %}
          end
        end

      {% end %}
    {% end %}
  end

  # Process EventSystem annotations
  macro finished
    {% verbatim do %}
      {% begin %}
        {% event_systems_map = {} of TypeNode => ArrayLiteral(Annotation) %}
        {% for obj in Object.all_subclasses.sort_by { |a| a.name } %}
          {% if obj.annotation(EventSystem) %}
            {% for anno in obj.annotations(EventSystem) %}
              {% context = anno.named_args[:context] %}
              {% array = event_systems_map[context] %}
              {% if array == nil %}
                {% event_systems_map[context] = [obj] %}
              {% else %}
                {% event_systems_map[context] = array + [obj] %}
              {% end %}
            {% end %}
          {% end %}
        {% end %}

        {% for context in event_systems_map %}
          class ::{{context.id}}::EventSystems < Feature
            def initialize(contexts : Contexts)
              @name = "{{context.id}}::EventSystems"
              {% for sys in event_systems_map[context].sort_by { |a| a.annotation(EventSystem).named_args[:priority] } %}
                add({{sys.id}}.new(contexts))
              {% end %}
            end
          end
        {% end %}
      {% end %}
    {% end %}
  end
end
