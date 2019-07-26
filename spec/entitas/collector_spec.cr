require "../spec_helper"

def new_collector
  ctx = new_context
  group = ctx.get_group(Entitas::Matcher.all_of(A))
  collector = Entitas::Collector.new(group, Entitas::Events::OnEntityAdded)
  {collector, group, ctx}
end

describe Entitas::Collector do
  describe "when observing a group with OnEntityAdded" do
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
    end
  end
end
