require "../spec_helper"

private def new_group_a
  Entitas::Group.new(Entitas::Matcher.all_of(A))
end

private def new_group_a_w_e
  matcher = Entitas::Matcher.all_of(A)
  matcher.component_names = ["A"]

  group = Entitas::Group.new(matcher)

  entity = new_entity_with_a
  group.handle_entity_silently(entity)
  {group, entity}
end

private def assert_contains(group, expected_entites)
  group.size.should eq expected_entites.size
  entities = group.get_entities
  entities.size.should eq expected_entites.size

  expected_entites.each do |e|
    entities.includes?(e).should be_true
    group.includes?(e).should be_true
  end
end

private def assert_not_contains(group, entity)
  group.size.should eq 0
  group.get_entities.should be_empty
  group.contains_entity?(entity).should be_false
end

describe Entitas::Group do
  describe "initial state" do
    it "doesn't have entities which haven't been added" do
      group_a = new_group_a
      e_a1 = new_entity
      e_a2 = new_entity
      group_a.get_entities.should be_empty
    end

    it "doesn't add entities to buffer" do
      group_a = new_group_a
      buff = Array(Entitas::Entity).new
      buff << new_entity_with_a
      ret_buff = group_a.get_entities(buff)
      ret_buff.should be_empty
      ret_buff.should be buff
    end

    it "is empty" do
      new_group_a.size.should eq 0
    end

    it "doesn't contain entity" do
      e_a1 = new_entity
      new_group_a.contains_entity?(e_a1).should be_false
    end
  end

  describe "when entity is matching" do
    it "adds matching entity" do
      group_a, e_a1 = new_group_a_w_e
      assert_contains(group_a, [e_a1])
    end

    it "fills buffer with entities" do
      group_a, e_a1 = new_group_a_w_e
      buff = Array(Entitas::Entity).new
      group_a.get_entities(buff)
      buff.size.should eq 1
      buff.first.should eq e_a1
    end

    it "clears buffer before filling" do
      buff = Array(Entitas::Entity).new
      group_a, e_a1 = new_group_a_w_e

      buff << new_entity
      buff << new_entity_with_a

      group_a.get_entities(buff)

      buff.size.should eq 1
      buff.first.should be e_a1
    end

    it "doesn't add same entity twice" do
      group_a = new_group_a
      e_a1 = new_entity_with_a
      group_a.handle_entity_silently(e_a1)
      assert_contains(group_a, [e_a1])
    end

    it "enumerates group" do
      group_a, e_a1 = new_group_a_w_e

      group_a.each do |entity|
        e = entity
      end

      group_a.size.should eq 1
      group_a.first.should be e_a1
    end

    it "returns enumerable" do
      group_a, e_a1 = new_group_a_w_e
      group_a.first.should eq e_a1
    end

    describe "when entity doesn't match anymore" do
      it "removes entity" do
        group_a, e_a1 = new_group_a_w_e
        e_a1.del_a
        group_a.handle_entity_silently(e_a1)
        assert_not_contains(group_a, e_a1)
      end
    end
  end
end
