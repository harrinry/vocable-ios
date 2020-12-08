//
//  GazeableCornerButton.swift
//  Vocable
//
//  Created by Joe Romero on 12/7/20.
//  Copyright © 2020 WillowTree. All rights reserved.
//

import UIKit

final class GazeableCornerButton: GazeableButton {

    var placement: CornerPlacement = .leadingTop

    var originPoint: CGPoint {
        switch placement {
        case .leadingTop:
            return CGPoint(x: 0, y: 0)
        case .leadingBottom:
            return CGPoint(x: 0, y: self.bounds.maxY)
        case .trailingTop:
            return CGPoint(x: self.bounds.maxX, y: 0)
        case .trailingBottom:
            return CGPoint(x: self.bounds.maxX, y: self.bounds.maxY)
        }
    }

    override func renderBackgroundImage(withFillColor fillColor: UIColor, withHighlight isHighlighted: Bool) -> UIImage {
        let image = UIGraphicsImageRenderer(bounds: bounds).image { _ in
            let backgroundFillColor: UIColor = backgroundColor ?? .collectionViewBackgroundColor
            let strokeColor = isHighlighted ? UIColor.cellBorderHighlightColor : fillColor
            let size = self.bounds.insetBy(dx: borderWidth, dy: borderWidth)
            let path = UIBezierPath()
            path.lineWidth = borderWidth
            let point = CGPoint(x: borderWidth, y: borderWidth)
            path.move(to: point)
            path.addLine(to: CGPoint(x: size.width, y: borderWidth))
            path.addArc(withCenter: point, radius: size.width, startAngle: 0, endAngle: .pi / 2, clockwise: true)
            path.addLine(to: point)
            backgroundFillColor.setFill()
            strokeColor.setStroke()
            path.fill()
            path.stroke()
        }
        let stretchableImage = image.resizableImage(withCapInsets: .zero, resizingMode: .stretch)
        return stretchableImage.rotationFor(placement: placement)
    }
}
