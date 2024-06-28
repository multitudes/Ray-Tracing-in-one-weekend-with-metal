import Metal
import MetalKit

guard let device = MTLCreateSystemDefaultDevice() else {
    fatalError("GPU not available")
}

let commandQueue = device.makeCommandQueue()

// Assuming `metalLibrary` contains your Metal shader code
let metalLibrary = device.makeDefaultLibrary()
let rayTracingKernel = metalLibrary?.makeFunction(name: "rayTracingKernel")
let pipelineState = try? device.makeComputePipelineState(function: rayTracingKernel!)

let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: 256, height: 256, mipmapped: false)
textureDescriptor.usage = [.shaderWrite, .shaderRead]
let outputTexture = device.makeTexture(descriptor: textureDescriptor)

let commandBuffer = commandQueue.makeCommandBuffer()
let commandEncoder = commandBuffer?.makeComputeCommandEncoder()
commandEncoder?.setComputePipelineState(pipelineState!)
commandEncoder?.setTexture(outputTexture, index: 0)

// Dispatch the compute work
let threadgroupSize = MTLSize(width: 8, height: 8, depth: 1)
let threadgroups = MTLSize(width: (256 + 7) / 8, height: (256 + 7) / 8, depth: 1)
commandEncoder?.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupSize)

commandEncoder?.endEncoding()
commandBuffer?.commit()
commandBuffer?.waitUntilCompleted()

// Now, `outputTexture` contains the rendered image. You can read its pixel data and save it to a file.
