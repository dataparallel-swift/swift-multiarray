# Serialization

Choose element-wise coding for an application format or native snapshots for
controlled, representation-compatible storage.

## Element-wise coding

``MultiArray`` conforms to `Encodable` or `Decodable` when its element does.
It encodes a versioned container with `count` and `values`, using each element's
own coding implementation. The representation tree does not need to be binary
encodable, so boxed values can participate when their element coding supports it.
Choose an encoder and an application compatibility policy for durable interchange.

@Snippet(path: "Guide", slice: "codable")

## Native binary snapshots

When the raw representation conforms to ``BinaryArrayData``, ``MultiArray/encode()``
and ``MultiArray/init(data:)`` copy native representation bytes:

@Snippet(path: "Guide", slice: "binary-snapshot")

Snapshots exclude boxed fields and omit unused capacity. Equal initialized
representations yield identical snapshots regardless of allocated capacity.
The format is native-endian and layout-dependent, not a stable wire format.
Round trips are supported within the same major library version on ABI-compatible
platforms. Use this for controlled caches or same-machine interchange, not
unversioned long-term storage across architectures or library versions.

Tags identify the raw representation, **not** the original Swift element type.
For example, `UInt8` and a `UInt8`-backed enum have the same tag. Decode as the
intended surface type: a matching tag alone cannot distinguish two application
types that use the same representation. ``RawValueRepresentation`` checks each
raw value against its domain, including when nested inside a product, but it
does not supply nominal type identity.

Decoding copies into a new allocation and throws ``BinaryMultiArrayError`` for
invalid headers, incompatible endianness or tags, inconsistent byte counts,
unrepresentable sizes, and invalid raw-value domains. The payload has no checksum;
corruption that remains a valid representation need not be detected. Encoding
traps if its layout size cannot be represented.
