import UIKit

extension CGPoint {
    func distanceTo(p1: CGPoint) -> CGFloat {
        let deltaX = x - p1.x
        let deltaY = p1.y - y
        return sqrt(deltaX * deltaX + deltaY * deltaY)
    }

    func angleTo(p1: CGPoint) -> CGFloat {
        let deltaX = p1.x - x
        let deltaY = p1.y - y
        let angle = atan2(deltaY, deltaX)
        return angle
    }
}
