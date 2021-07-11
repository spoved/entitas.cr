class InitializeSystemSpy
  include Entitas::Systems::InitializeSystem
  property did_initialize = 0

  def init
    self.did_initialize += 1
  end
end

class CleanupSystemSpy
  include Entitas::Systems::CleanupSystem
  property did_cleanup = 0

  def cleanup
    self.did_cleanup += 1
  end
end

class ExecuteSystemSpy
  include Entitas::Systems::ExecuteSystem
  property did_execute = 0

  def execute
    self.did_execute += 1
  end
end

class TearDownSystemSpy
  include Entitas::Systems::TearDownSystem
  property did_tear_down = 0

  def tear_down
    self.did_tear_down += 1
  end
end

class ReactiveSystemSpy < Entitas::ReactiveSystem
  include Entitas::Systems::CleanupSystem
  include Entitas::Systems::ExecuteSystem
  include Entitas::Systems::InitializeSystem
  include Entitas::Systems::TearDownSystem

  property did_initialize = 0
  property did_execute = 0
  property did_cleanup = 0
  property did_tear_down = 0
  property entities = Array(Entitas::IEntity).new

  property execute_action : Proc(Array(Entitas::IEntity), Nil)? = nil

  def get_trigger(context) : Entitas::ICollector
    @collector
  end

  def init
    self.did_initialize += 1
  end

  def execute(entities)
    {% if flag?(:entitas_enable_logging) %}
      Log.warn { "#{self} running execute(entities)" }
    {% end %}
    self.did_execute += 1
    self.entities = entities.map { |e| e.as(Entitas::IEntity) }

    if !execute_action.nil?
      execute_action.as(Proc(Array(Entitas::IEntity), Nil)).call(entities)
    end
  end

  def cleanup
    self.did_cleanup += 1
  end

  def tear_down
    self.did_tear_down += 1
  end
end

class MultiReactiveSystemSpy < Entitas::MultiReactiveSystem
  property did_execute = 0
  property entities = Array(Entitas::IEntity).new
  property execute_action : Proc(Array(Entitas::IEntity), Nil)? = nil

  def get_trigger(contexts : ::Contexts) : Array(Entitas::ICollector)
    [
      contexts.test.create_collector(TestMatcher.name_age),
      contexts.test2.create_collector(Test2Matcher.name_age),
    ] of Entitas::ICollector
  end

  def execute(entities)
    {% if flag?(:entitas_enable_logging) %}
      Log.debug { "#{self} running execute(entities)" }
    {% end %}

    self.did_execute += 1
    self.entities = entities.map { |e| e.as(Entitas::IEntity) }

    if !execute_action.nil?
      execute_action.as(Proc(Array(Entitas::IEntity), Nil)).call(entities)
    end
  end
end

class MultiTriggeredMultiReactiveSystemSpy < Entitas::MultiReactiveSystem
  property did_execute = 0
  property entities = Array(Entitas::IEntity).new
  property execute_action : Proc(Array(Entitas::IEntity), Nil)? = nil

  def get_trigger(contexts : ::Contexts) : Array(Entitas::ICollector)
    [
      contexts.test.create_collector(TestMatcher.name_age),
      contexts.test.create_collector(TestMatcher.name_age.removed),
    ] of Entitas::ICollector
  end

  def execute(entities)
    {% if flag?(:entitas_enable_logging) %}
      Log.debug { "#{self} running execute(entities)" }
    {% end %}
    self.did_execute += 1
    self.entities = entities.map { |e| e.as(Entitas::IEntity) }

    if !execute_action.nil?
      execute_action.as(Proc(Array(Entitas::IEntity), Nil)).call(entities)
    end
  end
end
