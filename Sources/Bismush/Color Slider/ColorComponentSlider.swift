//
//  ColorComponentSlider.swift
//  Bismush
//
//  Created by mzp on 5/15/22.
//

import Foundation
import SwiftUI

func BSMCeilToScale(value: Double, scale: Double) -> Double {
    ceil(scale * value) / scale
}

class ColorComponentSliderCell: NSSliderCell {
    static let barHeight: CGFloat = 10
    static let knobWidth: CGFloat = 6
    static let knobHeight: CGFloat = 6

    override func barRect(flipped _: Bool) -> NSRect {
        NSRect(
            x: Self.knobWidth,
            y: 0,
            width: trackRect.size.width - Self.knobWidth * 2,
            height: Self.barHeight
        )
    }

    override func knobRect(flipped: Bool) -> NSRect {
        let barRect = barRect(flipped: flipped)
        let x = BSMCeilToScale(
            value: (doubleValue / (maxValue - minValue)) * barRect.width,
            scale: Double(controlView?.window?.screen?.backingScaleFactor ?? 1)
        )

        return NSRect(
            x: barRect.minX + x - Self.knobWidth / 2,
            y: barRect.maxY,
            width: Self.knobWidth,
            height: Self.knobHeight
        )
    }

    override func drawBar(inside rect: NSRect, flipped _: Bool) {
        guard let context = NSGraphicsContext.current?.cgContext else {
            return
        }
        guard let gradient = CGGradient(colorsSpace: nil, colors: [
            (colorElementSlider?.startColor ?? .black).cgColor,
            (colorElementSlider?.endColor ?? .white).cgColor,
        ] as CFArray, locations: [CGFloat(0), CGFloat(1)]) else {
            return
        }
        context.saveGState()
        defer { context.restoreGState() }

        context.clip(to: [rect])
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: rect.minX, y: 0),
            end: CGPoint(x: rect.maxX, y: 0),
            options: []
        )
    }

    var colorElementSlider: ColorComponentSliderImpl? {
        controlView as? ColorComponentSliderImpl
    }

    override func drawKnob(_ knobRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else {
            return
        }
        context.saveGState()
        defer { context.restoreGState() }

        context.move(to: CGPoint(x: knobRect.minX, y: knobRect.maxY))
        context.addLine(to: CGPoint(x: knobRect.midX, y: knobRect.minY))
        context.addLine(to: CGPoint(x: knobRect.maxX, y: knobRect.maxY))
        NSColor.black.setStroke()
        context.strokePath()
    }
}

class ColorComponentSliderImpl: NSSlider {
    let startColor: NSColor
    let endColor: NSColor

    init(from startColor: NSColor, to endColor: NSColor) {
        self.startColor = startColor
        self.endColor = endColor

        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override class var cellClass: AnyClass? {
        get { ColorComponentSliderCell.self }
        set {}
    }
}

struct ColorComponentSlider: NSViewRepresentable {
    var startColor: NSColor
    var endColor: NSColor
    @Binding var value: Float

    func makeNSView(context _: Context) -> ColorComponentSliderImpl {
        ColorComponentSliderImpl(from: startColor, to: endColor)
    }

    func updateNSView(_ slider: ColorComponentSliderImpl, context: Context) {
        context.coordinator.parent = self
        slider.target = context.coordinator
        slider.action = #selector(Coordinator.onValueChanged)
        slider.floatValue = value
    }

    func makeAlignmentGuide() -> some View {
        alignmentGuide(VerticalAlignment.center, computeValue: { _ in
            (ColorComponentSliderCell.barHeight - ColorComponentSliderCell.knobHeight) / 2
        })
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator {
        var parent: ColorComponentSlider

        init(parent: ColorComponentSlider) {
            self.parent = parent
        }

        @objc
        func onValueChanged(sender: NSSlider) {
            parent.value = sender.floatValue
        }
    }
}

struct ColorComponentSlider_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 0) {
            Text("Color:")
            Color.red.frame(width: 1, height: 50)
            ColorComponentSlider(
                startColor: NSColor.black,
                endColor: NSColor.red,
                value: .constant(0.5)
            ).makeAlignmentGuide()
        }.frame(width: 400, height: 50)
    }
}
