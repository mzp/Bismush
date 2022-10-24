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

    var brushSize: Float {
        get { context.brushSize }
        set { context.brushSize = newValue }
    }

    public var viewSize: Size<ViewCoordinate> {
        get {
            interporater.viewSize
        }
        set {
            interporater.viewSize = newValue
        }
    }

    private var context: BMKLayerContext
    private let document: CanvasDocument

    private let interporater: BezierInterpolate
    private let mixer: WaterColorMix
    private let renderer: LayerDrawer
    private let sessionCommiter: SessionCommit
    private let commandQueue: CommandQueue

    public init(document: CanvasDocument, brushSize: Float = 50) {
        self.document = document

        context = BMKLayerContext(
            brushColor: SIMD4<Float>(0, 0, 0, 1),
            brushSize: brushSize,
            textureProjection: document.activeLayer.textureTransform.matrix,
            layerProjection: document.activeLayer.renderTransform.matrix
        )
        commandQueue = document.device.makeCommandQueue(label: #fileID)
        interporater = BezierInterpolate(document: document)
        mixer = WaterColorMix(document: document)
        renderer = LayerDrawer(document: document)
        sessionCommiter = SessionCommit(document: document)
    }

    public func commit() {
        BismushLogger.drawing.debug("brush session ends")
        document.device.scope(#function) {
            var commandBuffer = commandQueue.makeSequencialCommandBuffer(label: #function)
            draw(
                input0: points.get(index: 0) ?? points.last ?? .zero,
                input1: points.get(index: 1) ?? points.last ?? .zero,
                input2: points.get(index: 2) ?? points.last ?? .zero,
                input3: points.get(index: 3) ?? points.last ?? .zero,
                commandBuffer: commandBuffer
            )
            sessionCommiter.commit(commandBuffer: commandBuffer)
            commandBuffer.commit()
        }
        mixer.reset()
        session = nil
        document.commitSession()
        points.removeAll()
    }

    public func add(pressurePoint: PressurePoint) {
        BismushLogger.drawing.trace("\(#function): \(pressurePoint)")
        points.append(pressurePoint)
        if session == nil {
            mixer.reset()
            document.beginSession()
            session = Session(interporater: interporater, mixer: mixer, renderer: renderer)
            BismushLogger.drawing.debug("brush session starts")
        }
        if points.count == 4 {
            document.device.scope(#function) {
                var commandBuffer = commandQueue.makeSequencialCommandBuffer(label: #function)
                draw(
                    input0: points[0],
                    input1: points[1],
                    input2: points[2],
                    input3: points[3],
                    commandBuffer: commandBuffer
                )
                commandBuffer.commit()
            }
        } else {
            let count = points.count
            BismushLogger.drawing.info("Skip brush rendering (stored point=\(count))")
        }
    }

    private func draw(
        input0: PressurePoint,
        input1: PressurePoint,
        input2: PressurePoint,
        input3: PressurePoint,
        commandBuffer: SequencialCommandBuffer
    ) {
        guard let session = session else {
            return
        }

        let strokes = session.interporater.interpolate(
            input0: input0,
            input1: input1,
            input2: input2,
            input3: input3,
            commandBuffer: commandBuffer
        )

        points.removeAll()
        points.append(input3)

        session.mixer.mix(strokes: strokes, context: &context, commandBuffer: commandBuffer)

        var region: Rect<TexturePixelCoordinate> = Rect(
            points: [input0, input1, input2, input3]
                .map { document.activeLayer.texturePixelTransform * interporater.transform * $0.point }
        )
        region.add(top: -brushSize, left: -brushSize, bottom: -brushSize, right: -brushSize)
        session.renderer.draw(
            region: region,
            strokes: strokes,
            context: &context,
            commandBuffer: commandBuffer
        )
    }
}
