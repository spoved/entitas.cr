require "../spec_helper"

private def new_collector
  ctx = new_context
  group = ctx.get_group(Entitas::Matcher.all_of(A))
  collector = Entitas::Collector.new(group, Entitas::Events::GroupEvent::Added)
  {collector, group, ctx}
end

private def new_dual_removed_collector
  ctx = new_context
  group_a = ctx.get_group(Entitas::Matcher.all_of(A))
  group_b = ctx.get_group(Entitas::Matcher.all_of(B))
  collector = Entitas::Collector.new([group_a, group_b], [Entitas::Events::GroupEvent::Removed, Entitas::Events::GroupEvent::Removed])
  {collector, group_a, group_b, ctx}
end

private def new_dual_collector
  ctx = new_context
  group_a = ctx.get_group(Entitas::Matcher.all_of(A))
  group_b = ctx.get_group(Entitas::Matcher.all_of(B))
  collector = Entitas::Collector.new([group_a, group_b], [Entitas::Events::GroupEvent::Added, Entitas::Events::GroupEvent::Added])
  {collector, group_a, group_b, ctx}
end

private def new_dual_dual_collector
  ctx = new_context
  group_a = ctx.get_group(Entitas::Matcher.all_of(A))
  group_b = ctx.get_group(Entitas::Matcher.all_of(B))
  collector = Entitas::Collector.new([group_a, group_b], [Entitas::Events::GroupEvent::AddedOrRemoved, Entitas::Events::GroupEvent::AddedOrRemoved])
  {collector, group_a, group_b, ctx}
end

private def new_collector_wea
  collector, group, ctx = new_collector
  e = ctx.create_entity.add_a
  {collector, group, ctx, e}
end

private def new_collector_removed
  ctx = new_context
  group = ctx.get_group(Entitas::Matcher.all_of(A))
  collector = Entitas::Collector.new(group, Entitas::Events::GroupEvent::Removed)
  {collector, group, ctx}
end

private def new_collector_removed_wea
  collector, group, ctx = new_collector_removed
  e = ctx.create_entity.add_a
  {collector, group, ctx, e}
end

private def new_collector_both
  ctx = new_context
  group = ctx.get_group(Entitas::Matcher.all_of(A))
  collector = Entitas::Collector.new(group, Entitas::Events::GroupEvent::AddedOrRemoved)
  {collector, group, ctx}
end

private def new_collector_both_wea
  collector, group, ctx = new_collector_both
  e = ctx.create_entity.add_a
  {collector, group, ctx, e}
end

describe Entitas::Collector do
  describe "when observing a group with GroupEvent::Added" do
    it "is empty when nothing happend" do
      collector, _, _ = new_collector
      collector.entities.should be_empty
    end

    describe "when entity collected" do
      it "returns collected entities" do
        collector, _, ctx = new_collector
        e = ctx.create_entity.add_a

        entities = collector.entities

        entities.size.should eq 1
        entities.includes?(e).should be_true
      end

      it "only collects matching entities" do
        collector, _, ctx, e = new_collector_wea
        ctx.create_entity.add_b

        entities = collector.entities

        entities.size.should eq 1
        entities.includes?(e).should be_true
      end

      it "collects entities only once" do
        collector, _, _, e = new_collector_wea
        e.del_a.add_a

        entities = collector.entities

        entities.size.should eq 1
        entities.includes?(e).should be_true
      end

      it "clears collected entities" do
        collector, _, _, _ = new_collector_wea
        collector.clear
        collector.entities.should be_empty
      end

      it "clears collected entities on deactivation" do
        collector, _, ctx = new_collector
        ctx.create_entity.add_a
        collector.entities.should_not be_empty
        collector.deactivate
        collector.entities.should be_empty
      end

      it "doesn't collect entities when deactivated" do
        collector, _, ctx = new_collector
        collector.deactivate

        ctx.create_entity.add_a

        collector.entities.should be_empty
      end

      it "continues collecting when activated" do
        collector, _, ctx = new_collector
        collector.deactivate

        ctx.create_entity.add_a
        collector.entities.should be_empty
        collector.activate

        e = ctx.create_entity.add_a
        entities = collector.entities
        entities.size.should eq 1
        entities.includes?(e).should be_true
      end

      it "can to_s" do
        collector, _, _ = new_collector
        collector.to_s.should eq "Entitas::Collector(TestEntity)(Group(AllOf(A)))"
      end
    end

    describe "reference counting" do
      it "retains entity even after destroy" do
        did_execute = 0
        collector, _, _, e = new_collector_wea
        e.on_entity_released { did_execute += 1 }
        e.destroy
        e.retain_count.should eq 1

        e.retained_by?(collector).should be_true
        did_execute.should eq 0
      end

      it "releases entity when clearing collected entities" do
        collector, _, _, e = new_collector_wea
        e.destroy
        collector.clear
        e.retain_count.should eq 0
      end

      it "retains entities only once" do
        _, _, _, e = new_collector_wea
        e.replace_a(A.new)
        e.destroy
        e.retain_count.should eq 1
      end
    end
  end

  describe "when observing with GroupEvent::Removed" do
    it "returns collected entities" do
      collector, _, _, e = new_collector_removed_wea
      collector.entities.should be_empty

      e.del_a

      collector.size.should eq 1
      collector.includes?(e).should be_true
    end
  end

  describe "when observing with GroupEvent::AddedOrRemoved" do
    it "returns collected entities" do
      collector, _, _, e = new_collector_both_wea

      collector.size.should eq 1
      collector.includes?(e).should be_true
      collector.clear

      e.del_a
      entities = collector.entities
      entities.size.should eq 1
      entities.includes?(e).should be_true
    end
  end

  describe "when observing multiple groups" do
    it "throws when group count != GroupEvent count" do
      ctx = new_context
      group = ctx.get_group(Entitas::Matcher.all_of(A))

      expect_raises Entitas::Collector::Error do
        Entitas::Collector.new([group], [Entitas::Events::GroupEvent::Added, Entitas::Events::GroupEvent::Added])
      end
    end

    describe "when observing with GroupEvent::Added" do
      it "returns collected entities" do
        collector, _, _, ctx = new_dual_collector
        ea = ctx.create_entity.add_a
        eb = ctx.create_entity.add_b

        entities = collector.entities
        entities.size.should eq 2
        entities.includes?(ea).should be_true
        entities.includes?(eb).should be_true
      end

      it "can to_s" do
        collector, _, _, _ = new_dual_collector
        collector.to_s.should eq "Entitas::Collector(TestEntity)(Group(AllOf(A)), Group(AllOf(B)))"
      end
    end

    describe "when observing with GroupEvent::Removed" do
      it "returns collected entities" do
        collector, _, _, ctx = new_dual_removed_collector
        ea = ctx.create_entity.add_a
        eb = ctx.create_entity.add_b
        collector.should be_empty

        ea.del_a
        eb.del_b

        entities = collector.entities
        entities.size.should eq 2
        entities.includes?(ea).should be_true
        entities.includes?(eb).should be_true
      end
    end

    describe "when observing with GroupEvent::AddedOrRemoved" do
      it "returns collected entities" do
        collector, _, _, ctx = new_dual_dual_collector
        ea = ctx.create_entity.add_a
        eb = ctx.create_entity.add_b

        entities = collector.entities
        entities.size.should eq 2
        entities.includes?(ea).should be_true
        entities.includes?(eb).should be_true

        collector.clear
        collector.should be_empty

        ea.del_a
        eb.del_b

        entities = collector.entities
        entities.size.should eq 2
        entities.includes?(ea).should be_true
        entities.includes?(eb).should be_true
      end
    end

    it "when observing with mixed GroupEvents" do
      ctx = new_context
      group_a = ctx.get_group(Entitas::Matcher.all_of(A))
      group_b = ctx.get_group(Entitas::Matcher.all_of(B))
      collector = Entitas::Collector.new(
        [
          group_a,
          group_b,
        ],
        [
          Entitas::Events::GroupEvent::Added,
          Entitas::Events::GroupEvent::Removed,
        ]
      )
      ea = ctx.create_entity.add_a
      eb = ctx.create_entity.add_b

      entities = collector.entities
      entities.size.should eq 1
      entities.includes?(ea).should be_true
      entities.includes?(eb).should be_false

      collector.clear
      collector.should be_empty

      ea.del_a
      eb.del_b

      entities = collector.entities
      entities.size.should eq 1
      entities.includes?(ea).should be_false
      entities.includes?(eb).should be_true
    end
  end
end
