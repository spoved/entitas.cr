require "../../src/entitas"

@[Context(Test)]
@[Context(Test2)]
@[Context(MyTest)]
class A < Entitas::Component
end

@[Context(Test)]
@[Context(Test2)]
@[Context(MyTest)]
class B < Entitas::Component
end

@[Context(Test)]
@[Context(MyTest)]
class C < Entitas::Component
end

@[Context(Test)]
@[Context(Input)]
@[Context(MyTest)]
class D < Entitas::Component
end

@[Component::Unique]
@[Context(Test)]
@[Context(Input)]
@[Context(MyTest)]
class UniqueComp < Entitas::Component
  prop :size, Int32
  prop :default, String, default: "foo"
end
