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
- <doc:SupportAPI>

### Collections

- ``MultiArray``

### Define elements

- ``Generic``
- ``Generic()``
- ``Box()``
- ``Product``
- ``Unit``
- ``Box``
- ``RawValueRepresentation``

### Advanced representation support

- ``ArrayData``
- ``BinaryArrayData``
- ``BinaryMultiArrayError``
- ``Sum``
- ``T2``
- ``T3``
- ``T4``
- ``T5``
- ``T6``
- ``T7``
- ``T8``
- ``T9``
- ``T10``
- ``T11``
- ``T12``
- ``T13``
- ``T14``
- ``T15``
- ``T16``
