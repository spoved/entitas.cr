class Entitas::Error < Exception
  class MethodNotImplemented < Error
  end

  class ContextInfo < Error
  end
end

# Component error class raised when an issue is encountered
class Entitas::Component::Error < ::Entitas::Error; end

class Entitas::Collector::Error < ::Entitas::Error; end

class Entitas::Entity::Error < ::Entitas::Error
  class IsNotEnabled < Error; end

  class DoesNotHaveComponent < Error; end

  class AlreadyHasComponent < Error; end

  class IsAlreadyRetainedByOwner < Error; end

  class IsNotRetainedByOwner < Error; end

  class IsNotDestroyedException < Error; end
end

class Entitas::Group::Error < ::Entitas::Error
  class SingleEntity < Error; end
end

class Entitas::EntityIndex::Error < Entitas::Error
  private class ContextError < Error
    getter context : Context
    getter name : String

    def initialize(@context, @name); end
  end

  # throws when adding an EntityIndex with same name
  class AlreadyExists < ContextError
    def to_s(io)
      io << "Cannot add EntityIndex '#{name}' to context '#{context}'! " \
            "An EntityIndex with this name has already been added."
    end
  end

  # throws when EntityIndex for key doesn't exist
  class DoesNotExist < ContextError
    def to_s(io)
      io << "Cannot get EntityIndex '#{name}' from context '#{context}'! " \
            "No EntityIndex with this name has been added."
    end
  end
end

class Entitas::Context::Error < Entitas::Error
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

  class Index < Error
    class DoesNotExist < Index; end
  end
end

class Entitas::Matcher::Error < Exception
  def initialize(@length : Int32); end

  def to_s(io)
    io << "matcher.indices.size must be 1 but was #{@length}"
  end
end
