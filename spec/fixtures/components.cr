require "../../src/entitas"

@[Context(Test)]
class A < Entitas::Component
end

@[Context(Test)]
class B < Entitas::Component
end

@[Context(Test)]
class C < Entitas::Component
end

@[Context(Test)]
@[Context(Input)]
class D < Entitas::Component
end

@[Component::Unique]
@[Context(Test)]
@[Context(Input)]
class UniqueComp < Entitas::Component
  prop :size, Int32
  prop :default, String, default: "foo"
end
