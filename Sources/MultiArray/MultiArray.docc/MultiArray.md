# ``MultiArray``

Store heterogeneous values in a vector-friendly struct-of-arrays layout.

## Overview

``MultiArray`` decomposes each element into scalar fields and stores every
field in a separate contiguous buffer. Its collection interface reconstructs
ordinary Swift values at the boundary, while operations over the complete
collection can benefit from improved locality and automatic vectorization.

The ``Generic()`` macro derives the required representation:

@Snippet(path: "Guide", slice: "point")

Use a `MultiArray` where you would otherwise use an `Array`, provided that the
element type conforms to ``Generic``.

## Topics

### Getting started

- <doc:RepresentingCustomTypes>
- <doc:StorageAndVectorization>

### Collections and representations

- ``MultiArray``
- ``Generic``
- ``Product``
- ``Unit``
- ``Box``
- ``RawValueRepresentation``
