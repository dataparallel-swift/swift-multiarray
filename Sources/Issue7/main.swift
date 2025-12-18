
import MultiArray

struct Vec3<Element>: Generic where Element: Generic {
    typealias RawRepresentation = T3<Element, Element, Element>.RawRepresentation

    let x, y, z: Element

    var rawRepresentation: RawRepresentation {
        T3(self.x, self.y, self.z).rawRepresentation
    }

    init(x: Element, y: Element, z: Element) {
        self.x = x
        self.y = y
        self.z = z
    }

    init(from rep: RawRepresentation) {
        let T3 = T3<Element, Element, Element>(from: rep)
        self = Vec3(x: T3._0, y: T3._1, z: T3._2)
    }
}

struct Zone: Generic {
    typealias RawRepresentation = T2<Int, Vec3<Float>>.RawRepresentation

    let id: Int
    let position: Vec3<Float>

    var rawRepresentation: RawRepresentation {
        T2(self.id, self.position).rawRepresentation
    }

    init(id: Int, position: Vec3<Float>) {
        self.id = id
        self.position = position
    }

    init(from rep: RawRepresentation) {
        self = Zone(id: rep._0, position: .init(from: rep._1))
    }

    func move(dx: Float = 0, dy: Float = 0, dz: Float = 0) -> Zone {
        Zone(id: self.id, position: Vec3(x: self.position.x + dx, y: self.position.y + dy, z: self.position.z + dz))
    }
}

func arrayMove(_ xs: Array<Zone>) -> Array<Zone> {
    xs.map{ $0.move(dx: 1) }
}

func multiarrayMove(_ xs: MultiArray<Zone>) -> MultiArray<Zone> {
    xs.map{ $0.move(dx: 1) }
}

