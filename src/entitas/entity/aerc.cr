require "../error"
require "../entity"

module Entitas
  module AERC
    def retain_count : Int32
      @_retain_count
    end

    def retain(obj)
      raise Entitas::MethodNotImplementedError
    end

    def release(obj)
      raise Entitas::MethodNotImplementedError
    end
  end

  class SafeAERC(T)
    include Entitas::AERC

    @_owners = Array(T).new
    @_entity : Entitas::Entity

    def retain_count : Int32
      @_owners.size
    end

    def owners
      @_owners
    end

    def initialize(entity : Entitas::Entity)
      @_entity = entity
    end

    def retain(owner : T)
      if owners.includes(owner)
        raise new Entitas::EntityIsAlreadyRetainedByOwnerException.new(@_entity, owner)
      else
        owners.push owner
      end
    end

    def release(owner : T)
      if !owners.includes(owner)
        raise new Entitas::EntityIsNotRetainedByOwnerException.new(@_entity, owner)
      else
        owners.delete owner
      end
    end
  end

  class UnsafeAERC
    include Entitas::AERC

    def retain(obj)
      @_retain_count += 1
    end

    def release(obj)
      @_retain_count -= 1
    end
  end
end
