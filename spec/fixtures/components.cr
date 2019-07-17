require "../spec_helper"

class A < Entitas::Component
end

class B < Entitas::Component
end

class C < Entitas::Component
end

class D < Entitas::Component
end

@[Component::Unique]
class UniqueComp < Entitas::Component
  prop :size, Int32?
  prop :default, String, default: "foo"
end
