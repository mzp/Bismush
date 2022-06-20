//
//  BrushRenderer.swift
//  Bismush
//
//  Created by Hiro Mizuno on 3/26/22.
//

import CoreGraphics
import Metal
import simd

public class Brush {
    struct Session {
        var interporater: BezierInterpolate
        var mixer: WaterColorMix
        var renderer: StrokeRenderer
    }

    private var session: Session?

    private let store: CanvasRenderer
    private var renderer: StrokeRenderer?
    private var points = RingBuffer<PressurePoint>(capacity: 4)

    public var color: BismushColor {
        get { BismushColor(rawValue: context.brushColor) }
        set {
            BismushLogger.drawing.info("""
                Brush color changed: \
            \(newValue.red, format: .fixed(precision: 2)), \
            \(newValue.green, format: .fixed(precision: 2)), \
            \(newValue.blue, format: .fixed(precision: 2)), \
            \(newValue.alpha, format: .fixed(precision: 2)))
            """)

            context.brushColor = newValue.rawValue
        }
    }

    private var context: BMKLayerContext

    public init(store: CanvasRenderer, brushSize: Float = 50) {
        self.store = store

        context = BMKLayerContext(
            brushColor: SIMD4<Float>(0, 0, 0, 1),
            brushSize: brushSize,
            textureProjection: store.activeLayer.textureTransform.matrix,
            layerProjection: store.activeLayer.renderTransform.matrix
        )
    }

    public func clear() {
        BismushLogger.drawing.debug("brush session ends")
        session = nil
        points.removeAll()
    }

    public func add(pressurePoint: PressurePoint, viewSize: Size<ViewCoordinate>) {
        BismushLogger.drawing.trace("""
        Add: \(pressurePoint.pressure, format: .fixed(precision: 3)) \
        on (\(pressurePoint.point.x, format: .fixed(precision: 2)), \
        \(pressurePoint.point.y, format: .fixed(precision: 2)))
        """)
        points.append(pressurePoint)

        if points.count == 4 {
            if session == nil {
                let interporater = BezierInterpolate(store: store, size: viewSize)
                let mixer = WaterColorMix(store: store, context: context)
                let renderer = StrokeRenderer(store: store, context: context)
                session = Session(interporater: interporater, mixer: mixer, renderer: renderer)
                BismushLogger.drawing.debug("brush session starts")
            }
            guard let session = session else {
                assertionFailure()
                return
            }
            let strokes = session.interporater.interpolate(
                input0: points[0],
                input1: points[1],
                input2: points[2],
                input3: points[3]
            )
            session.mixer.mix(strokes: strokes)
            session.renderer.draw(strokes: strokes)
        } else {
            let count = points.count
            BismushLogger.drawing.info("Skip brush rendering (stored point=\(count))")
        }
    }
}
