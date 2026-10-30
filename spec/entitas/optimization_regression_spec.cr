require "../spec_helper"

class OptimizationMultiSpy < Entitas::MultiReactiveSystem
  property accept = false
  property fail_filter = false
  property filter_calls = 0
  property executions = 0
  property inspect_filter : Proc(Entitas::IEntity, Nil)? = nil

  def get_trigger(contexts : ::Contexts) : Array(Entitas::ICollector)
    [contexts.test.create_collector(TestMatcher.name_age),
     contexts.test.create_collector(TestMatcher.name_age.removed)] of Entitas::ICollector
  end

  def filter(entity)
    @filter_calls += 1
    @inspect_filter.try &.call(entity)
    raise "filter failed" if @fail_filter
    @accept
  end

  def execute(entities : Array(Entitas::IEntity))
    @executions += 1
  end
end

describe "Entitas optimized lifecycle regressions" do
  it "clears a multi-collector batch even when every entity is filtered out" do
    contexts = Contexts.new
    system = OptimizationMultiSpy.new(contexts)
    entity = contexts.test.create_entity.add_name_age(name: "test", age: 1)
    system.execute
    system.filter_calls.should eq 1
    system.accept = true
    system.execute
    system.executions.should eq 0
    system.filter_calls.should eq 1
  end

  it "cleans retained batches when filtering raises" do
    contexts = Contexts.new
    system = OptimizationMultiSpy.new(contexts)
    entity = contexts.test.create_entity.add_name_age(name: "test", age: 1)
    system.fail_filter = true
    expect_raises(Exception, "filter failed") { system.execute }
    entity.retained_by?(system).should be_false
    system.fail_filter = false
    system.accept = true
    system.execute
    system.executions.should eq 0
  end

  it "retains a destroyed entity before clearing its last collector owners" do
    contexts = Contexts.new
    system = OptimizationMultiSpy.new(contexts)
    entity = contexts.test.create_entity.add_name_age(name: "test", age: 1)
    entity.destroy
    system.inspect_filter = ->(e : Entitas::IEntity) do
      e.retained_by?(system).should be_true
      contexts.test.create_entity.should_not be e.as(TestEntity)
    end
    system.execute
    entity.retain_count.should eq 0
    contexts.test.create_entity.should be entity
  end

  it "does not lose outer group notifications during nested component mutation" do
    ctx = new_context
    a = ctx.get_group(Entitas::Matcher.all_of(A))
    either = ctx.get_group(Entitas::Matcher.any_of(A, B))
    observed = [] of String
    a.on_entity_added { observed << "a" }
    either.on_entity_added do |event|
      observed << "either"
      event.entity.as(TestEntity).add_b
    end
    ctx.create_entity.add_a
    observed.should eq ["either", "a"]
  end

  it "reuses an immediately destroyed entity exactly once" do
    ctx = new_context
    entity = ctx.create_entity
    entity.destroy
    ctx.create_entity.should be entity
    ctx.create_entity.should_not be entity
  end

  it "reuses equivalent groups regardless of matcher insertion order" do
    ctx = new_context
    ctx.get_group(Entitas::Matcher.all_of(A, B)).should be ctx.get_group(Entitas::Matcher.all_of(B, A))
  end

  it "updates combined matcher indices after chaining" do
    matcher = Entitas::Matcher.all_of(A)
    matcher.indices.includes?(B.index).should be_false
    matcher.any_of(B)
    matcher.indices.includes?(B.index).should be_true
  end

  it "isolates a registered group from later mutation of the caller's matcher" do
    ctx = new_context
    matcher = Entitas::Matcher.all_of(A)
    group = ctx.get_group(matcher)
    matcher.none_of(B)
    entity = ctx.create_entity.add_b.add_a
    group.has_entity?(entity).should be_true
  end
end

# A custom predicate cannot be represented by all/any/none indices alone.
class CustomPredicateMatcher < Entitas::Matcher
  def initialize(@accept : Bool)
    super()
    all_of(A)
  end

  def matches?(entity : Entitas::Entity) : Bool
    @accept && super
  end
end

describe "custom matcher compatibility" do
  it "preserves subclass predicates and isolates equal-display instances from base matchers" do
    ctx = new_context
    entity = ctx.create_entity.add_a
    reject = CustomPredicateMatcher.new(false)
    accept = CustomPredicateMatcher.new(true)
    base = Entitas::Matcher.all_of(A)
    reject.to_s.should eq(base.to_s)
    accept.to_s.should eq(base.to_s)

    rejected = ctx.get_group(reject)
    accepted = ctx.get_group(accept)
    standard = ctx.get_group(base)
    rejected.has_entity?(entity).should be_false
    accepted.has_entity?(entity).should be_true
    standard.has_entity?(entity).should be_true
    rejected.should_not be accepted
    accepted.should_not be standard
    ctx.get_group(reject).should be rejected
    ctx.get_group(accept).should be accepted
    ctx.get_group(Entitas::Matcher.all_of(A)).should be standard
  end

  it "keeps colliding groups discoverable and releases their entities on reset in either registration order" do
    {false, true}.each do |base_first|
      ctx = new_context
      base = Entitas::Matcher.all_of(A)
      accept = CustomPredicateMatcher.new(true)
      reject = CustomPredicateMatcher.new(false)
      matchers = base_first ? [base, accept, reject] : [accept, reject, base]
      registered = matchers.map { |matcher| ctx.get_group(matcher) }
      ctx.groups.size.should eq(3)
      ctx.groups[matchers.first.to_s].should be registered.first
      registered.each { |group| ctx.groups.values.includes?(group).should be_true }
      entity = ctx.create_entity.add_a
      ctx.reset
      entity.retain_count.should eq(0)
      registered.each { |group| group.has_entity?(entity).should be_false }
      reused = ctx.create_entity.add_a
      reused.should be entity
      ctx.get_group(base).has_entity?(reused).should be_true
      ctx.get_group(accept).has_entity?(reused).should be_true
      ctx.get_group(reject).has_entity?(reused).should be_false
      ctx.reset
    end
  end
end
