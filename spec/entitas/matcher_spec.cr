require "../spec_helper"

private def new_entities
  e_a = new_entity
  e_a.add_a

  e_b = new_entity
  e_b.add_b

  e_c = new_entity
  e_c.add_c

  e_ab = new_entity
  e_ab.add_a
  e_ab.add_b

  e_abc = new_entity
  e_abc.add_a
  e_abc.add_b
  e_abc.add_c

  {e_a, e_b, e_c, e_ab, e_abc}
end

private def assert_indices_contain(indices, expected_indices)
  indices.size.should eq expected_indices.size
  indices.should eq expected_indices
end

private def new_matcher_all_of
  Entitas::Matcher(TestEntity).all_of(A, B)
end

private def new_matcher_any_of
  Entitas::Matcher(TestEntity).any_of(A, B)
end

private def new_matcher_none_of
  Entitas::Matcher(TestEntity).none_of(A, B)
end

private def all_of_none_of
  Entitas::Matcher(TestEntity).all_of(A, B).none_of(C, D)
end

private def any_of_none_of
  Entitas::Matcher(TestEntity).any_of(A, B).none_of(C, D)
end

private def all_of_any_of
  Entitas::Matcher(TestEntity).all_of(A, B).any_of(C, D)
end

private def all_of_ab
  Entitas::Matcher(TestEntity).all_of(A, B)
end

private def all_of_ba
  Entitas::Matcher(TestEntity).all_of(B, A)
end

describe Entitas::Matcher do
  e_a, e_b, e_c, e_ab, e_abc = new_entities

  describe "#all_of" do
    it "has all indices" do
      m = new_matcher_all_of
      assert_indices_contain m.indices, [::Entitas::Component::Index::A, ::Entitas::Component::Index::B]
      assert_indices_contain m.all_of_indices, [::Entitas::Component::Index::A, ::Entitas::Component::Index::B]
    end

    it "has all indices without duplicates" do
      m = Entitas::Matcher(TestEntity).all_of(A, A, B, B)
      assert_indices_contain m.indices, [::Entitas::Component::Index::A, ::Entitas::Component::Index::B]
      assert_indices_contain m.all_of_indices, [::Entitas::Component::Index::A, ::Entitas::Component::Index::B]
    end

    it "caches indices" do
      m = new_matcher_all_of
      m.indices.should be m.indices
    end

    it "doesn't match" do
      new_matcher_all_of.matches?(e_a).should be_false
    end

    it "matches" do
      m = new_matcher_all_of
      m.matches?(e_ab).should be_true
      m.matches?(e_abc).should be_true
    end

    it "merges matchers to new matcher" do
      m1 = Entitas::Matcher(TestEntity).all_of(A)
      m2 = Entitas::Matcher(TestEntity).all_of(B)
      m3 = Entitas::Matcher(TestEntity).all_of(C)

      merged_matcher = Entitas::Matcher(TestEntity).all_of(m1, m2, m3)

      assert_indices_contain merged_matcher.indices, [::Entitas::Component::Index::A,
                                                      ::Entitas::Component::Index::B,
                                                      ::Entitas::Component::Index::C]
      assert_indices_contain merged_matcher.all_of_indices, [::Entitas::Component::Index::A,
                                                             ::Entitas::Component::Index::B,
                                                             ::Entitas::Component::Index::C]
    end

    it "merges matchers to new matcher without duplicates" do
      m1 = Entitas::Matcher(TestEntity).all_of(A)
      m2 = Entitas::Matcher(TestEntity).all_of(A)
      m3 = Entitas::Matcher(TestEntity).all_of(B)

      merged_matcher = Entitas::Matcher(TestEntity).all_of(m1, m2, m3)

      assert_indices_contain merged_matcher.indices, [::Entitas::Component::Index::A,
                                                      ::Entitas::Component::Index::B]
      assert_indices_contain merged_matcher.all_of_indices, [::Entitas::Component::Index::A,
                                                             ::Entitas::Component::Index::B]
    end

    it "throws when merging matcher with more than one index" do
      m1 = new_matcher_all_of
      expect_raises Entitas::Matcher::Error do
        Entitas::Matcher(TestEntity).all_of(m1)
      end
    end

    it "can to_s" do
      new_matcher_all_of.to_s.should eq "AllOf(0, 1)"
    end

    it "uses component_names when set" do
      m = new_matcher_all_of
      m.component_names = ["one", "two", "three"]
      m.to_s.should eq "AllOf(one, two)"
    end

    it "uses component_names when merged matcher to_s" do
      m1 = Entitas::Matcher(TestEntity).all_of(B)
      m2 = Entitas::Matcher(TestEntity).all_of(C)
      m3 = Entitas::Matcher(TestEntity).all_of(D)

      m2.component_names = ["m_0", "m_1", "m_2", "m_3"]

      merged_matcher = Entitas::Matcher(TestEntity).all_of(m1, m2, m3)
      merged_matcher.to_s.should eq "AllOf(m_1, m_2, m_3)"
    end
  end

  describe "#any_of" do
    it "has all indices" do
      m = new_matcher_any_of
      assert_indices_contain m.indices, [::Entitas::Component::Index::A, ::Entitas::Component::Index::B]
      assert_indices_contain m.any_of_indices, [::Entitas::Component::Index::A, ::Entitas::Component::Index::B]
    end

    it "has all indices without duplicates" do
      m = Entitas::Matcher(TestEntity).any_of(A, A, B, B)
      assert_indices_contain m.indices, [::Entitas::Component::Index::A, ::Entitas::Component::Index::B]
      assert_indices_contain m.any_of_indices, [::Entitas::Component::Index::A, ::Entitas::Component::Index::B]
    end

    it "caches indices" do
      m = new_matcher_any_of
      m.indices.should be m.indices
    end

    it "doesn't match" do
      new_matcher_any_of.matches?(e_c).should be_false
    end

    it "matches" do
      m = new_matcher_any_of
      m.matches?(e_a).should be_true
      m.matches?(e_b).should be_true
      m.matches?(e_abc).should be_true
    end

    it "merges matchers to new matcher" do
      m1 = Entitas::Matcher(TestEntity).any_of(A)
      m2 = Entitas::Matcher(TestEntity).any_of(B)
      m3 = Entitas::Matcher(TestEntity).any_of(C)

      merged_matcher = Entitas::Matcher(TestEntity).any_of(m1, m2, m3)

      assert_indices_contain merged_matcher.indices, [::Entitas::Component::Index::A,
                                                      ::Entitas::Component::Index::B,
                                                      ::Entitas::Component::Index::C]
      assert_indices_contain merged_matcher.any_of_indices, [::Entitas::Component::Index::A,
                                                             ::Entitas::Component::Index::B,
                                                             ::Entitas::Component::Index::C]
    end

    it "merges matchers to new matcher without duplicates" do
      m1 = Entitas::Matcher(TestEntity).any_of(A)
      m2 = Entitas::Matcher(TestEntity).any_of(B)
      m3 = Entitas::Matcher(TestEntity).any_of(B)

      merged_matcher = Entitas::Matcher(TestEntity).any_of(m1, m2, m3)

      assert_indices_contain merged_matcher.indices, [::Entitas::Component::Index::A,
                                                      ::Entitas::Component::Index::B]
      assert_indices_contain merged_matcher.any_of_indices, [::Entitas::Component::Index::A,
                                                             ::Entitas::Component::Index::B]
    end

    it "throws when merging matcher with more than one index" do
      m1 = new_matcher_any_of
      expect_raises Entitas::Matcher::Error do
        Entitas::Matcher(TestEntity).any_of(m1)
      end
    end

    it "can to_s" do
      new_matcher_any_of.to_s.should eq "AnyOf(0, 1)"
    end
  end

  describe "#all_of.none_of" do
    it "has all indices" do
      m = all_of_none_of
      assert_indices_contain m.indices, [
        ::Entitas::Component::Index::A,
        ::Entitas::Component::Index::B,
        ::Entitas::Component::Index::C,
        ::Entitas::Component::Index::D,
      ]
      assert_indices_contain m.all_of_indices, [::Entitas::Component::Index::A, ::Entitas::Component::Index::B]
      assert_indices_contain m.none_of_indices, [::Entitas::Component::Index::C, ::Entitas::Component::Index::D]
    end

    it "has all indices without duplicates" do
      m = Entitas::Matcher(TestEntity).all_of(A, A, B).none_of(B, C, C)
      assert_indices_contain m.indices, [
        ::Entitas::Component::Index::A,
        ::Entitas::Component::Index::B,
        ::Entitas::Component::Index::C,
      ]
      assert_indices_contain m.all_of_indices, [::Entitas::Component::Index::A, ::Entitas::Component::Index::B]
      assert_indices_contain m.none_of_indices, [::Entitas::Component::Index::B, ::Entitas::Component::Index::C]
    end

    it "caches indices" do
      m = all_of_none_of
      m.indices.should be m.indices
    end

    it "doesn't match" do
      all_of_none_of.matches?(e_abc).should be_false
    end

    it "matches" do
      m = all_of_none_of
      m.matches?(e_ab).should be_true
    end

    it "mutates existing matcher" do
      m1 = new_matcher_all_of
      m2 = m1.none_of(B)
      m1.should be m2
    end

    it "mutates existing merged matcher" do
      m1 = Entitas::Matcher(TestEntity).all_of(A)
      m2 = Entitas::Matcher(TestEntity).all_of(B)
      m3 = Entitas::Matcher(TestEntity).all_of(m1)
      m4 = m3.none_of(m2)

      m3.should be m4

      assert_indices_contain m3.indices, [::Entitas::Component::Index::A, ::Entitas::Component::Index::B]
      assert_indices_contain m3.all_of_indices, [::Entitas::Component::Index::A]
      assert_indices_contain m3.none_of_indices, [::Entitas::Component::Index::B]
    end

    it "can to_s" do
      all_of_none_of.to_s.should eq "AllOf(0, 1).NoneOf(2, 3)"
    end

    it "uses component_names when component_names set" do
      matcher = all_of_none_of
      matcher.component_names = ["one", "two", "three", "four", "five"]
      matcher.to_s.should eq "AllOf(one, two).NoneOf(three, four)"
    end
  end

  describe "#any_of.none_of" do
    it "has all indices" do
      m = any_of_none_of

      assert_indices_contain m.indices, [
        ::Entitas::Component::Index::A,
        ::Entitas::Component::Index::B,
        ::Entitas::Component::Index::C,
        ::Entitas::Component::Index::D,
      ]
      assert_indices_contain m.any_of_indices, [::Entitas::Component::Index::A, ::Entitas::Component::Index::B]
      assert_indices_contain m.none_of_indices, [::Entitas::Component::Index::C, ::Entitas::Component::Index::D]
    end

    it "has all indices without duplicates" do
      m = Entitas::Matcher(TestEntity).any_of(A, A, B).none_of(B, C, C)

      assert_indices_contain m.indices, [
        ::Entitas::Component::Index::A,
        ::Entitas::Component::Index::B,
        ::Entitas::Component::Index::C,
      ]
      assert_indices_contain m.any_of_indices, [::Entitas::Component::Index::A, ::Entitas::Component::Index::B]
      assert_indices_contain m.none_of_indices, [::Entitas::Component::Index::B, ::Entitas::Component::Index::C]
    end

    it "caches indices" do
      m = any_of_none_of
      m.indices.should be m.indices
    end

    it "doesn't match" do
      any_of_none_of.matches?(e_abc).should be_false
    end

    it "matches" do
      m = any_of_none_of
      m.matches?(e_a).should be_true
      m.matches?(e_b).should be_true
    end

    it "mutates existing matcher" do
      m1 = Entitas::Matcher(TestEntity).any_of(A)
      m2 = m1.none_of(B)
      m1.should be m2

      assert_indices_contain m1.indices, [
        ::Entitas::Component::Index::A,
        ::Entitas::Component::Index::B,
      ]
      assert_indices_contain m1.any_of_indices, [::Entitas::Component::Index::A]
      assert_indices_contain m1.none_of_indices, [::Entitas::Component::Index::B]
    end

    it "mutates existing merged matcher" do
      m1 = Entitas::Matcher(TestEntity).all_of(A)
      m2 = Entitas::Matcher(TestEntity).all_of(B)
      m3 = Entitas::Matcher(TestEntity).any_of(m1)
      m4 = m3.none_of(m2)

      m3.should be m4

      assert_indices_contain m3.indices, [::Entitas::Component::Index::A, ::Entitas::Component::Index::B]
      assert_indices_contain m3.any_of_indices, [::Entitas::Component::Index::A]
      assert_indices_contain m3.none_of_indices, [::Entitas::Component::Index::B]
    end

    it "can to_s" do
      any_of_none_of.to_s.should eq "AnyOf(0, 1).NoneOf(2, 3)"
    end

    it "uses component_names when component_names set" do
      matcher = any_of_none_of
      matcher.component_names = ["one", "two", "three", "four", "five"]
      matcher.to_s.should eq "AnyOf(one, two).NoneOf(three, four)"
    end
  end

  describe "#all_of.any_of" do
    it "has all indices" do
      m = all_of_any_of
      assert_indices_contain m.indices, [
        ::Entitas::Component::Index::A,
        ::Entitas::Component::Index::B,
        ::Entitas::Component::Index::C,
        ::Entitas::Component::Index::D,
      ]
      assert_indices_contain m.all_of_indices, [::Entitas::Component::Index::A, ::Entitas::Component::Index::B]
      assert_indices_contain m.any_of_indices, [::Entitas::Component::Index::C, ::Entitas::Component::Index::D]
    end

    it "has all indices without duplicates" do
      m = Entitas::Matcher(TestEntity).all_of(A, A, B).any_of(B, C, C)
      assert_indices_contain m.indices, [
        ::Entitas::Component::Index::A,
        ::Entitas::Component::Index::B,
        ::Entitas::Component::Index::C,
      ]
      assert_indices_contain m.all_of_indices, [::Entitas::Component::Index::A, ::Entitas::Component::Index::B]
      assert_indices_contain m.any_of_indices, [::Entitas::Component::Index::B, ::Entitas::Component::Index::C]
    end

    it "caches indices" do
      m = all_of_any_of
      m.indices.should be m.indices
    end

    it "doesn't match" do
      all_of_any_of.matches?(e_ab).should be_false
    end

    it "matches" do
      m = all_of_any_of
      m.matches?(e_abc).should be_true
    end

    it "mutates existing matcher" do
      m1 = Entitas::Matcher(TestEntity).all_of(A)
      m2 = m1.any_of(B)
      m1.should be m2
      assert_indices_contain m1.indices, [
        ::Entitas::Component::Index::A,
        ::Entitas::Component::Index::B,
      ]
      assert_indices_contain m1.all_of_indices, [::Entitas::Component::Index::A]
      assert_indices_contain m1.any_of_indices, [::Entitas::Component::Index::B]
    end

    it "mutates existing merged matcher" do
      m1 = Entitas::Matcher(TestEntity).all_of(A)
      m2 = Entitas::Matcher(TestEntity).all_of(B)
      m3 = Entitas::Matcher(TestEntity).all_of(m1)
      m4 = m3.any_of(m2)

      m3.should be m4

      assert_indices_contain m3.indices, [::Entitas::Component::Index::A, ::Entitas::Component::Index::B]
      assert_indices_contain m3.all_of_indices, [::Entitas::Component::Index::A]
      assert_indices_contain m3.any_of_indices, [::Entitas::Component::Index::B]
    end

    it "can to_s" do
      all_of_any_of.to_s.should eq "AllOf(0, 1).AnyOf(2, 3)"
    end

    it "uses component_names when component_names set" do
      matcher = all_of_any_of
      matcher.component_names = ["one", "two", "three", "four", "five"]
      matcher.to_s.should eq "AllOf(one, two).AnyOf(three, four)"
    end
  end

  describe "equals" do
    it "equals equal AllOfMatcher" do
      m1 = all_of_ab
      m2 = all_of_ab
      m1.should_not be m2
      m1.should eq m2
    end
  end
end
