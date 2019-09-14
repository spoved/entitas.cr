require "./error"
require "./entity"
require "spoved/logger"

module Entitas
  abstract struct AERC
    {% if flag?(:entitas_enable_logging) %}spoved_logger{% end %}

    @_retain_count = 0

    def retain_count : Int32
      @_retain_count
    end

    def retain(obj)
      raise Entitas::Error::MethodNotImplemented.new
    end

    def release(obj)
      raise Entitas::Error::MethodNotImplemented.new
    end
  end

  # Automatic Entity Reference Counting (AERC)
  # is used internally to prevent pooling retained entities.
  # If you use retain manually you also have to
  # release it manually at some point.
  # SafeAERC checks if the entity has already been
  # retained or released. It's slower, but you keep the information
  # about the owners.
  struct SafeAERC < Entitas::AERC
    # @_owners : Set(UInt64) = Set(UInt64).new
    @_owners : Array(UInt64) = Array(UInt64).new(4)
    @_entity : Entitas::Entity

    private def entity
      @_entity
    end

    def retain_count : Int32
      @_owners.size
    end

    def owners
      @_owners
    end

    def initialize(entity : Entitas::Entity)
      @_entity = entity
    end

    private def add?(id : UInt64)
      !!(owners.push(id) unless includes?(id))
    end

    private def delete?(id : UInt64)
      !!(owners.delete(id) if includes?(id))
    end

    def retain(owner)
      {% if flag?(:entitas_enable_logging) %}logger.debug("Retaining #{entity} for #{owner} : #{owner.object_id}", "SafeAERC"){% end %}
      unless self.add?(owner.object_id)
        raise Entitas::Entity::Error::IsAlreadyRetainedByOwner.new "entity: #{entity} owner: #{owner}"
      end
    end

    def release(owner)
      {% if flag?(:entitas_enable_logging) %}logger.debug("Releasing #{entity} from #{owner} : #{owner.object_id}", "SafeAERC"){% end %}
      unless self.delete?(owner.object_id)
        raise Entitas::Entity::Error::IsNotRetainedByOwner.new "entity: #{entity} owner: #{owner}"
      end
    end

    def includes?(id : UInt64)
      owners.includes?(id)
    end

    def includes?(owner)
      owners.includes?(owner.object_id)
    end
  end

  struct UnsafeAERC < Entitas::AERC
    def retain(obj)
      @_retain_count += 1
    end

    def release(obj)
      @_retain_count -= 1
    end
  end
end
