require "./bench_helper"
require "./*"

1.times do
  Benchmark.bm do |x|
    tasks.each &.call(x)
  end
end

# ContextCreateEntity:                    90 ms
# ContextDestroyEntity:                   31 ms
# ContextDestroyAllEntities:              31 ms
# ContextGetGroup:                        6 ms
# ContextGetEntities:                     3 ms
# ContextHasEntity:                       2 ms
# ContextOnEntityReplaced:                23 ms
#
# EntityAddComponent:                     552 ms
# EntityGetComponent:                     41 ms
# EntityGetComponents:                    4 ms
# EntityHasComponent:                     4 ms
# EntityRemoveAddComponent:               937 ms
# EntityReplaceComponent:                 179 ms
#
# MatcherEquals:                          363 ms
# MatcherGetHashCode:                     22 ms
# ContextCreateBlueprint:                 464 ms
# NewInstanceT:                           563 ms
# NewInstanceActivator:                   954 ms
# EntityIndexGetEntity:                   45 ms
#
# ObjectGetProperty:                      19 ms
#
# CollectorIterateCollectedEntities:      460 ms
# CollectorActivate:                      1 ms
