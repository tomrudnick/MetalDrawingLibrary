//
//  Utils.swift
//  metalTest
//
//  Created by Tom Rudnick on 22.03.22.
//

import Foundation
import UIKit

// MARK: - Point Utils
extension CGPoint {
    
    func between(min: CGPoint, max: CGPoint) -> CGPoint {
        return CGPoint(x: x.valueBetween(min: min.x, max: max.x),
                       y: y.valueBetween(min: min.y, max: max.y))
    }
    
    // MARK: - Codable utils
    static func make(from ints: [Int]) -> CGPoint {
        return CGPoint(x: CGFloat(ints.first ?? 0) / 10, y: CGFloat(ints.last ?? 0) / 10)
    }
    
    func encodeToInts() -> [Int] {
        return [Int(x * 10), Int(y * 10)]
    }
}

extension CGSize {
    // MARK: - Codable utils
    static func make(from ints: [Int]) -> CGSize {
        return CGSize(width: CGFloat(ints.first ?? 0) / 10, height: CGFloat(ints.last ?? 0) / 10)
    }
    
    func encodeToInts() -> [Int] {
        return [Int(width * 10), Int(height * 10)]
    }
}

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: origin.x + width / 2, y: origin.y + height / 2)
    }
}
