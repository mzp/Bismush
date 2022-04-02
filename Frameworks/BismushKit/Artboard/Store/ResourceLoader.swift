//
//  ResourceLoader.swift
//  Bismush
//
//  Created by mzp on 4/2/22.
//

import Metal
import MetalKit

class ResourceLoader {
    enum FunctionName: String, CustomStringConvertible {
        var description: String {
            rawValue
        }

        case layerVertex = "layer_vertex"
        case layerFragment = "layer_fragment"
        case strokePoint = "stroke_point"
        case strokeVertex = "stroke_vertex"
        case strokeFragment = "stroke_fragment"
    }

    private let device: MTLDevice
    private let library: MTLLibrary
    private let bundle: Bundle

    init(device: MTLDevice) {
        self.device = device
        let bundle = Bundle(for: ArtboardLayerRenderer.self)
        let library = try! device.makeDefaultLibrary(bundle: bundle)
        BismushLogger.metal.debug("Using library: \(library.description) in \(bundle)")

        self.library = library
        self.bundle = bundle
    }

    func function(_ name: FunctionName) -> MTLFunction {
        guard let function = library.makeFunction(name: name.rawValue) else {
            BismushLogger.metal.fault("Can't load shader function: \(name.rawValue)")
            fatalError("shader load error")
        }
        return function
    }

    func bultinTexture(name: String) -> MTLTexture {
        let loader = MTKTextureLoader(device: device)
        let url = bundle.url(forResource: name, withExtension: "png")!
        return try! loader.newTexture(URL: url)
    }
}
