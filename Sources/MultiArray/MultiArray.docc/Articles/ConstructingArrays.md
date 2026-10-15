# Constructing Arrays

Choose a safe initializer for ordinary values; use uninitialized construction
only when writing directly into the final allocation matters.

## Ordinary construction

Create a ``MultiArray`` from a collection or sequence, repeat one value with
``MultiArray/init(repeating:count:)``, or generate values by index with
``MultiArray/init(count:with:)``. These initializers manage partial
initialization for you.

@Snippet(path: "Guide", slice: "ordinary-construction")

Counts and capacities must be nonnegative. If a generating closure throws,
already initialized elements are destroyed and its error is rethrown. Repeating
a reference-valued payload retains it rather than cloning the referenced object.

## Synchronous prefix construction

The synchronous
``MultiArray/init(unsafeUninitializedCapacity:initializingWith:)-6xxxc`` gives
its closure a by-value ``UnsafeUninitializedMultiArrayBuffer`` view and an
`inout` initialized count, initially zero. Initialize exactly the prefix `0..<initializedCount`; the
result has that count, which may be smaller than the requested capacity.

@Snippet(path: "Guide", slice: "sync-construction")

Update the count even if the closure throws, typically with `defer`. Reporting
too few initialized elements leaks their resources. The count is checked against
the range `0...capacity`, and reporting a count outside that range traps. Do not
initialize a slot twice, let the view escape, or use it after the closure finishes.
On throw, the reported prefix is destroyed and the closure's typed error is
rethrown. Prefix coverage is the caller's responsibility; it is not checked.

## Asynchronous arbitrary-order construction

When `Element.RawRepresentation` conforms to ``PartialInitializationArrayData``,
the async overload
``MultiArray/init(unsafeUninitializedCapacity:initializingWith:)-7w9ux`` accepts
a `sending` closure with an `inout` initialized count, initially zero, and
permits initialization in any order, including concurrent writes to distinct
indices when both `Element` and its raw
representation are `Sendable`:

@Snippet(path: "Guide", slice: "async-construction")

Initialize exactly the prefix `0..<initializedCount` before the body returns
successfully, and report its length through the count. The count must be between
zero and capacity, inclusive; violations trap on both success and throw.
Join all child tasks before returning or throwing, including after cancellation
or a child failure. Update the count in the parent after joining; child tasks
must not concurrently access it. The buffer must not escape the body or remain
in use after it finishes. Writes to the same index from concurrent
tasks are a data race and are undefined. This initializer publishes the reported
prefix on success without moving elements; the allocation retains its capacity.

The tracking trait governs both cleanup and completeness checks. For a
representation with `requiresInitializationTracking == true`, failure destroys
only initialized elements, using flags rather than the reported count, so
scattered initialization before a throw is supported. In debug builds, a
duplicate write, a missing prefix slot, or an initialized slot outside the
reported prefix triggers an assertion when there is no race. Release builds do
not run these checks, though they still use the flags for cleanup on failure.
Representations with tracking disabled need no per-index cleanup and do not
check for missing slots in any build. If you return with an uninitialized slot,
later access may read an invalid value. The caller must uphold the completeness
promise in every build.

If the body throws, the initializer rethrows its declared failure type after
cleanup. Cancellation takes effect only when the body observes it and throws.
The async overload is available on macOS 10.15, iOS 13, tvOS 13, and watchOS 9
or later.
