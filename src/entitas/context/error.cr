module Entitas
  class Context
    class Error < Exception
      class Info < Error
        getter context : Entitas::Context
        getter context_info : Entitas::Context::Info

        def initialize(@context, @context_info)
        end

        def to_s(io)
          io << "Invalid ContextInfo for '#{context}'!\nExpected " \
                "#{context.total_components} component_name(s) but got " \
                "#{context_info.component_names.size}:#{context_info.component_names.join("\n")}"
        end
      end

      class StillHasRetainedEntities < Error
        getter context : Context
        getter retained_entities : Set(Entity)

        def initialize(@context, @retained_entities); end
      end

      class UnknownEvent < Error; end

      class EntityIndexError < Error
        getter context : Context
        getter name : String

        def initialize(@context, @name); end
      end

      class EntityIndexDoesAlreadyExist < EntityIndexError
        def to_s(io)
          io << "Cannot add EntityIndex '#{name}' to context '#{context}'! " \
                "An EntityIndex with this name has already been added."
        end
      end

      class EntityIndexDoesNotExist < EntityIndexError
        def to_s(io)
          io << "Cannot get EntityIndex '#{name}' from context '#{context}'! " \
                "No EntityIndex with this name has been added."
        end
      end
    end
  end
end
