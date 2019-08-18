require "./error"
require "./entity"
require "spoved/logger"

module Entitas
  abstract class AERC
    {% if !flag?(:disable_logging) %}spoved_logger{% end %}

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
  class SafeAERC < Entitas::AERC
    @_owners = Array(UInt64).new
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

    def retain(owner)
      if includes?(owner)
        raise Entitas::Entity::Error::IsAlreadyRetainedByOwner.new "entity: #{entity} owner: #{owner}"
      else
        {% if !flag?(:disable_logging) %}logger.debug("Retaining #{entity} for #{owner}", "SafeAERC"){% end %}
        owners.push owner.object_id
      end
    end

    def release(owner)
      if !includes?(owner)
        raise Entitas::Entity::Error::IsNotRetainedByOwner.new "entity: #{entity} owner: #{owner}"
      else
        {% if !flag?(:disable_logging) %}logger.debug("Releasing #{entity} from #{owner}", "SafeAERC"){% end %}
        owners.delete owner.object_id
      end
    end

    def includes?(owner)
      owners.includes?(owner.object_id)
    end
  end

  class UnsafeAERC < Entitas::AERC
    def retain(obj)
      @_retain_count += 1
    end

    def release(obj)
      @_retain_count -= 1
    end
  end
end
