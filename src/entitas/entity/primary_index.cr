require "./index"

module Entitas
  abstract class Entity
    class PrimaryIndex(TKey) < Index(TKey)
      getter index : Hash(TKey, Entitas::Entity) = Hash(TKey, Entitas::Entity).new

      def self.new(name : String, group : Entitas::Group, get_key : Proc(Entitas::Entity, Entitas::Component?, TKey))
        instance = self.class.allocate
        instance.initialize(
          name,
          group,
          get_key,
          ->(_entity : Entitas::Entity, _component : Entitas::Component?, _keys : Array(TKey)) {},
          true
        )
        instance.activate
        instance
      end

      def self.new(name : String, group : Entitas::Group, get_keys : Proc(Entitas::Entity, Entitas::Component?, Array(TKey)))
        instance = self.class.allocate
        instance.initialize(
          name,
          group,
          ->(_entity : Entitas::Entity, _component : Entitas::Component?, _key : TKey) {},
          get_keys,
          false
        )
        instance.activate
        instance
      end

      def activate
        super
        self.index_entities(self.group)
      end

      def get_entity(key : TKey) : Entitas::Entity?
        self.index[key]?
      end

      def clear
        index.values.each do |entity|
          if entity.aerc.is_a?(Entitas::SafeAERC)
            entity.release(self) if entity.aerc.includes?(self)
          else
            entity.release(self)
          end
        end
        index.clear
      end

      def add_entity(key : TKey, entity : Entitas::Entity)
        if self.index[key]?
          raise Entitas::Entity::Index::Error.new "Entity for key '#{key}' already exists! " \
                                                  "Only one entity for a primary key is allowed."
        end

        self.index[key] = entity

        if entity.aerc.is_a?(Entitas::SafeAERC)
          entity.retain(self) unless entity.aerc.includes?(self)
        else
          entity.retain(self)
        end
      end

      def del_entity(key : TKey, entity : Entitas::Entity)
        self.index.delete(key)

        if entity.aerc.is_a?(Entitas::SafeAERC)
          entity.release(self) if entity.aerc.includes?(self)
        else
          entity.release(self)
        end
      end
    end
  end
end
