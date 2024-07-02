import PlaygroundSupport
import MetalKit

// first create the device which will be used by the MTKView
guard let device = MTLCreateSystemDefaultDevice(), let commandQueue = device.makeCommandQueue() else {
	fatalError("GPU is not supported")
}

// this is the view created with MTKView
let frame = CGRect(x: 0, y: 0, width: 600, height: 600)
let view = MTKView(frame: frame, device: device)


// the playgrounds would not allow to save a metal file in sources like the swift files
// so I need to pass it as inline variable
let shader = """
#include <metal_stdlib>
using namespace metal;

kernel void compute(
	texture2d<float, access::write> output [[texture(0)]],
	uint2 gid [[thread_position_in_grid]])
{
	int width = output.get_width();
	int height = output.get_height();
	float2 uv = float2(gid) / float2(width, height);
	// Interpolate color from black at top-left to yellow at bottom-right
	float4 color = float4(uv.x, uv.y, 0.0, 1.0); // RGB(0,0,0) to RGB(1,1,0)
	output.write(color, gid);
}
"""
let library = try device.makeLibrary(source: shader, options: nil)
guard let kernel = library.makeFunction(name: "compute") else {
	fatalError()
}

let pipelineState = try device.makeComputePipelineState(function: kernel)

guard
	let commandBuffer = commandQueue.makeCommandBuffer(),
	let drawable = view.currentDrawable,
	let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
	fatalError("drawable")
}
commandEncoder.setComputePipelineState(pipelineState)
let texture = drawable.texture
commandEncoder.setTexture(texture, index: 0)

let width = pipelineState.threadExecutionWidth
let height = pipelineState.maxTotalThreadsPerThreadgroup / width
let threadsPerThreadgroup = MTLSize(
	width: width, height: height, depth: 1)
let gridWidth = texture.width
let gridHeight = texture.height
let threadGroupCount = MTLSize(
	width: (gridWidth + width - 1) / width,
	height: (gridHeight + height - 1) / height,
	depth: 1)
commandEncoder.dispatchThreadgroups(
	threadGroupCount,
	threadsPerThreadgroup: threadsPerThreadgroup)

commandEncoder.endEncoding()
commandBuffer.present(drawable)
commandBuffer.commit()

PlaygroundPage.current.liveView = view


