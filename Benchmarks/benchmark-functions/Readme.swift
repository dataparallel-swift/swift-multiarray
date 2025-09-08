import MultiArray

public struct Vec3<Element> {
    @usableFromInline let x, y, z: Element
    @inlinable @inline(__always) public init(x: Element, y: Element, z: Element) {
        self.x = x
        self.y = y
        self.z = z
    }
}

extension Vec3: Generic where Element: Generic {
    public typealias Rep = T3<Element,Element,Element>.Rep
    @inlinable @inline(__always) public static func from(_ self: Self) -> Self.Rep {
        T3.from(T3(self.x, self.y, self.z))
    }
    @inlinable @inline(__always) public static func to(_ rep: Self.Rep) -> Self {
        let T3 = T3<Element,Element,Element>.to(rep)
        return Vec3(x: T3._0, y: T3._1, z: T3._2)
    }
}

public struct Zone {
    @usableFromInline let id: Int
    @usableFromInline let position: Vec3<Float>
    @inlinable @inline(__always) public init(id: Int, position: Vec3<Float>) {
        self.id = id
        self.position = position
    }
}

extension Zone: Generic {
    public typealias Rep = T2<Int, Vec3<Float>>.Rep
    @inlinable @inline(__always) public static func from(_ self: Self) -> Self.Rep {
        T2.from(T2(self.id, self.position))
    }
    @inlinable @inline(__always) public static func to(_ rep: Self.Rep) -> Self {
        let T2 = T2<Int, Vec3<Float>>.to(rep)
        return Zone(id: T2._0, position: T2._1)
    }
}

extension Zone {
    public func move(dx: Float = 0, dy: Float = 0, dz: Float = 0) -> Zone {
        Zone(id: self.id, position: Vec3(x: self.position.x + dx, y: self.position.y + dy, z: self.position.z + dz))
    }
}

public func readme1_array(zones: Array<Zone>) -> Array<Zone>
{
    zones.map{ $0.move(dx: 1) }
}

public func readme1_multiarray(zones: MultiArray<Zone>) -> MultiArray<Zone>
{
    zones.map{ $0.move(dx: 1) }
}

public func readme2_array(zones: Array<Zone>) -> Array<Float>
{
    zones.map{ $0.position.x }
}

public func readme2_multiarray(zones: MultiArray<Zone>) -> MultiArray<Float>
{
    zones.map{ $0.position.x }
}

