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
        var renderer: LayerDrawer
    }

    private var session: Session?

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
    private let document: CanvasDocument

    var brushSize: Float {
        get { context.brushSize }
        set { context.brushSize = newValue }
    }

    public init(document: CanvasDocument, brushSize: Float = 50) {
        self.document = document

        context = BMKLayerContext(
            brushColor: SIMD4<Float>(0, 0, 0, 1),
            brushSize: brushSize,
            textureProjection: document.activeLayer.textureTransform.matrix,
            layerProjection: document.activeLayer.renderTransform.matrix
        )
    }

    public func commit() {
        BismushLogger.drawing.debug("brush session ends")
        draw(
            input0: points.get(index: 0) ?? points.last ?? .zero,
            input1: points.get(index: 1) ?? points.last ?? .zero,
            input2: points.get(index: 2) ?? points.last ?? .zero,
            input3: points.get(index: 3) ?? points.last ?? .zero
        )
        let sessionCommiter = SessionCommit(document: document, context: context)
        sessionCommiter.commit()
        session = nil
        document.commitSession()
        points.removeAll()
    }

    public func add(pressurePoint: PressurePoint, viewSize: Size<ViewCoordinate>) {
        BismushLogger.drawing.trace("""
        Add: \(pressurePoint.pressure, format: .fixed(precision: 3)) \
        on (\(pressurePoint.point.x, format: .fixed(precision: 2)), \
        \(pressurePoint.point.y, format: .fixed(precision: 2)))
        """)
        points.append(pressurePoint)
        if session == nil {
            document.beginSession()
            let interporater = BezierInterpolate(document: document, size: viewSize)
            let mixer = WaterColorMix(document: document, context: context)
            let renderer = LayerDrawer(document: document, context: context)
            session = Session(interporater: interporater, mixer: mixer, renderer: renderer)
            BismushLogger.drawing.debug("brush session starts")
        }
        if points.count == 4 {
            draw(
                input0: points[0],
                input1: points[1],
                input2: points[2],
                input3: points[3]
            )
        } else {
            let count = points.count
            BismushLogger.drawing.info("Skip brush rendering (stored point=\(count))")
        }
    }

    private func draw(
        input0: PressurePoint,
        input1: PressurePoint,
        input2: PressurePoint,
        input3: PressurePoint
    ) {
        guard let session = session else {
            return
        }
        let strokes = session.interporater.interpolate(
            input0: input0,
            input1: input1,
            input2: input2,
            input3: input3
        )
        points.removeAll()
        points.append(input3)
        session.mixer.mix(strokes: strokes)
        document.activeTexture?.load(
            points: strokes.map {
                Point(rawValue: $0.point.xy)
            }
        )
        session.renderer.draw(strokes: strokes)
    }
}
