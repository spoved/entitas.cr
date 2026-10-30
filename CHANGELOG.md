# Changelog

## 1.5.1

- Retain reactive-system batches before clearing collectors, and release captured entities and clear buffers even when filtering or execution raises. Filtered-out batches no longer leak into a later execution.
- Preserve pending group notifications when an event callback changes another component. Nested notifications use separate buffers while preserving existing dispatch order.
- Reuse one group for structurally equivalent matchers regardless of component insertion order. Snapshot standard matcher criteria so later chaining does not change a registered group, while preserving custom matcher subclass behavior; invalidate cached component indices when chaining.
- Reduce temporary collection allocation during component-index enumeration and collector insertion. Deduplicate multi-reactive batches by entity identity while preserving their first-seen order.
- Align release CI with the existing Crystal 1.14 minimum, matching build CI and the shard requirement.

### Compatibility

Equivalent standard matchers now intentionally share a group even when their display strings differ. Registration snapshots standard matcher criteria: later chaining on the caller's matcher does not change an existing group. Call `get_group` again with changed criteria to request another group. Custom `Matcher` subclasses retain their original instance and overridden matching behavior; only repeated use of that same instance reuses its group, with no structural deduplication or snapshotting. Keep their component-index criteria fixed after registration, as before.

The public `groups` map retains the first registered display string. When distinct groups share that display string, later entries receive a numeric suffix so all groups remain discoverable. Direct mutation of a registered group's matcher criteria or the public groups map remains unsupported.

Reactive callbacks retain their existing signatures. Events produced while filtering or executing a captured batch remain queued for a later batch. Calling `execute` recursively on the same reactive system is unsupported. Contexts and their groups/collectors still require a single owner; this release does not add shared-context thread safety.
