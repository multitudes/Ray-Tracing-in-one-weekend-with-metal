# Ray Tracing in one weekend with metal
A spin of the popular book series adapted for the power of Apple Silicon. 
I did a C version here: [Ray-Tracing-in-One-Weekend-in-C](https://github.com/multitudes/Ray-Tracing-in-One-Weekend-in-C) but i am curious to see how to reimplement this with Metal and learn Metal along the way. 

Metal was announced at the Worldwide Developers Conference (WWDC) on June 2, 2014, an Apple alternative to Direct3D (which is part of DirectX - Windows) and OpenGL. Apple created a new language to program the GPU directly via shader functions. This is the Metal Shading Language (MSL) based on the C++11 specification. A year later at WWDC15, Apple announced two Metal sub-frameworks: MetalKit and Metal Performance Shaders (MPS). You typically usse Metal to have access to the GPU. GPUs belong to a special class of computation called Single Instruction Multiple Data (SIMD) and optimized for throughput (how much data can be processed in one unit of time).   

The beauty of the book [Raytracing in one weekend](https://raytracing.github.io/books/RayTracingInOneWeekend.html)  is that it doesnt use any libraries and instead writes to a ppm file which is a very easy to understand and text based format. 
Using a highlevel framework like metal which is optimized to output image on the screen, it turn out that it is not that straightforward or useful to output the image creating a ppm file, so I will just conform and create a small app which will output the image to the screen.  The takeaway here is to understand how the metal frameworks handles the rendering of the image and how to use the GPU to do the heavy lifting.  

## rendering models and pipelines
Typically the CPU creates a command buffer which will be passed to the GPU for rendering.  
Metal works with pipelines for maximum efficiency.  

In ideal conditions, light travels through the air as a ray following a straight line until it hits a surface.  
Once the ray hits something, any combination of the following: absorption, reflection, refraction, and scattering may occur.
• Light gets absorbed into the surface.
• Light gets reflected by the surface.
• Light gets refracted through the surface.
• Light gets scattered from another point under the surface.

There are two main approaches to rendering graphics:

### A traditional pipeline model is a raster-model, which uses a rasterizer to color the pixels on the screen.  
It is a faster rendering technique, highly optimized for GPUs. This model scales well for larger scenes and rendering of games where scenes need to be rendered quickly and perfect piel accuracy is not always required.  With metal this involves triangle rendering and the use of a vertex and fragment shader.

In pseudocode:
```
for each triangle in the scene:
if visible:
	mark triangle location
	apply triangle color
if not visible:
	discard triangle
```

### The raytracing model involves shooting rays from the camera, out of the screen and into the scene. 
it is more parallelizable and handles shadows, reflection and refractions more precisely but it is also sloweer. When you’re rendering static scenes or animated movies this is the way to go.
In pseudocode:
```
for each pixel on the screen:
	if there's an intersection (hit):
		identify the object hit
		change pixel color
		optionally bounce the ray
	if there's no intersection (miss):
		discard ray
		leave pixel color unchanged
```	

The ray-model has a few variants; among the most popular are ray casting, ray tracing, path tracing and raymarching.  
- Ray-Casting has been introduced in 1968 and popularized by the game Wolfenstein 3D in 1992, also thanks to the id Software team and John Carmack. A ray casting algorithm states this:
For each cell in the floor map, shoot a ray from the camera, and find the closest object blocking the ray path. The number of rays cast mostly equal the screen width and the rendering can be optimized to be very fast.

- Ray tracing was introduced in 1979 by Turner Whitted. Ray tracing shoots a ray for each pixel (width * height) and the quality of the images is much better but takes a long time to render so the images will be stored on disk. 

```
For each pixel on the screen:
For each object in the scene:
If there's an intersection (hit):
Select the closest hit object
Recursively trace reflection/refraction rays
Color the pixel in the selected object's color
```
The main idea of the Monte Carlo integration — also known as the Russian Roulette method — is to shoot multiple primary rays for each pixel, and when there’s a hit in the scene, 
shoot just K more secondary rays (usually just one more) in a random direction for each of the primary rays shot:
```
For each pixel on the screen:
	Reset the pixel color C.
		For each sample (random direction):
		Shoot a ray and trace its path.
		C += incoming radiance from ray.
		C /= number of samples
```

## Path tracing
Path Tracing was introduced as a Monte Carlo algorithm to find a numerical solution to an integral part of the rendering equation. James Kajiya presented the rendering equation in 1986.  

There is raymarching, a technique that uses a ray to find the intersection with a surface. It is used in real-time rendering and is a good fit for volumetric rendering. It is also used in raytracing to find the intersection of a ray with a surface.


In the context of ray tracing, an implicit surface is a type of surface that is defined by an equation, typically in the form `f(x, y, z) = 0`. The function `f` describes a 3D scalar field, and the surface is the set of points where this function equals zero.

This is in contrast to explicit surfaces, which are defined by a set of vertices and polygons (like triangles in a mesh), or parametric surfaces, which are defined by a function mapping parameters to points in space.

Implicit surfaces are particularly useful in ray tracing because they can represent complex or organic shapes that are difficult to model with polygons. They also make it easy to perform certain operations like blending or warping surfaces.

However, finding the intersection of a ray with an implicit surface can be more computationally intensive than with explicit or parametric surfaces, because it often involves solving a non-linear equation. in raymarching the intersection is approximated.  
Using SDFs, you can march along the ray until you get close enough to an object.  This is inexpensive to compute compared to precisely determining intersections.

## Signed Distance Functions (SDF) 
SDF describes the distance between any given point and the surface of an object in the scene. An SDF returns a negative number if the point is inside that object or positive otherwise.  

Example of a shader function in Metal that renders a circle using SDF:

```cpp
#include <metal_stdlib>
using namespace metal;

kernel void compute(texture2d<float, access::write> output [[texture(0)]],
                    uint2 gid [[thread_position_in_grid]]) {
  int width = output.get_width();
  int height = output.get_height();
  float2 uv = float2(gid) / float2(width, height);
  uv = uv * 2.0 - 1.0;
  float4 color = float4(0.41, 0.61, 0.86, 1.0);
  
  // SDF
  float radius = 0.25;
  float2 center = float2(0.0);
  float distance = length(uv - center) - radius;
  if (distance < 0.0) {
	color = float4(1.0, 0.0, 0.0, 1.0); // red in rgba
  }
  
  output.write(color, gid);
}
```

- In Metal, a kernel function is a special type of function that can be called from your host code (running on the CPU) and executed on the GPU. Kernel functions are declared with the `kernel` keyword in Metal. They are used for compute operations, as opposed to graphics operations.
- Each thread operates on a different piece of data, the thread position (`gid`) is a 2D coordinate that identifies a pixel in the `output` texture. Each thread is responsible for computing the color of one pixel, and the thread position tells it which pixel to compute. The `[[thread_position_in_grid]]` attribute in the function parameter tells the Metal shading language that `gid` should be automatically populated with the current thread's position when the function is called. 
- In the above the lines : `` say that uv will start at the top left and it is normalized and then scaled to the range of -1 to 1. So the top left will be -1,-1 and the bottom right will be 1,1.
- the float4 color is the color of the circle, the default is a blueish color.
- The SDF in this case is calculated by finding the distance between the point and the center of the circle and then subtracting the radius. If the distance is less than 0, the point is inside the circle and the color is changed to yellow. The color is then written to the output texture at the current thread position.

## Playground
Open a playground on macos and select the blank template.  
We start by importing the MetalKit framework and creating a reference to our GPU. At the same time the code checks if a suitable GPU is found if not it will stop here.
```swift
import MetalKit

guard let device = MTLCreateSystemDefaultDevice() else {
  fatalError("GPU is not supported")
}

/* Create the frame and the view to be displayed on screen: */
let frame = CGRect(x: 0, y: 0, width: 600, height: 600)
let view = MTKView(frame: frame, device: device)

/* Create the CPU commandqueue */
guard let queue = device.makeCommandQueue() else {
  fatalError("Could not create a command queue")
}

/* get the shader file and initialize the pipeline state with the function I have in my shader.metal file. */
var pipelineState: MTLComputePipelineState!
do {
	guard let path = Bundle.main.path(forResource: "Shaders", ofType: "metal") else { fatalError() }
	let input = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
	let library = try device.makeLibrary(source: input, options: nil)
	guard let kernel = library.makeFunction(name: "compute") else { fatalError() }
	/*The compute pipeline state is created using the kernel function and the device.*/
	pipelineState = try device.makeComputePipelineState(function: kernel)
} catch {
	print(error)
}

/* Then draw the view using the pipeline state and the command queue. */
```swift
guard let commandBuffer = queue.makeCommandBuffer(),
          let commandEncoder = commandBuffer.makeComputeCommandEncoder(),
          let drawable = view.currentDrawable else { fatalError() }
/* the compute pipeline state is set on the command encoder. This tells the GPU which compute function to use for the computation.*/
commandEncoder.setComputePipelineState(pipelineState)

commandEncoder.setTexture(drawable.texture, index: 0)
/* the optimal number of threads that can run concurrently on the GPU. This value is hardware-dependent.*/
let w = pipelineState.threadExecutionWidth

/*This calculates the height of a threadgroup based on the maximum number of threads that can be in a threadgroup and the previously calculated width.*/
let h = pipelineState.maxTotalThreadsPerThreadgroup / w
/*This creates a MTLSize object representing the size of a threadgroup. The third parameter is 1 because we're working with 2D data (an image), so the depth is 1.*/
let threadsPerGroup = MTLSizeMake(w, h, 1)
/*The grid size is the same as the image size because we want to process each pixel of the image.*/
let threadsPerGrid = MTLSizeMake(Int(view.drawableSize.width),
									Int(view.drawableSize.height), 1)
/*This dispatches the threads to the GPU.*/
commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
commandEncoder.endEncoding()
commandBuffer.present(drawable)
commandBuffer.commit()


PlaygroundPage.current.liveView = view
```

The line `commandEncoder.setComputePipelineState(pipelineState)` is executed on the CPU, but it's setting up instructions for the GPU.  
In Metal, the `MTLComputeCommandEncoder` object is used to encode (i.e., write) commands into a command buffer. These commands are then executed by the GPU.  
The actual computation work done by the GPU is determined by the `pipelineState`, which includes a reference to the compute function to be used by the GPU.  

In Metal, threads are organized into threadgroups, which are further organized into a grid that covers the entire computational domain. 

So, if you have a 256x256 image and your `threadExecutionWidth` is 16 (for example), you would have 16x16 threadgroups covering the entire image, and each threadgroup would process a 16x16 pixel block of the image.

The `dispatchThreads` method is used to dispatch the threads to the GPU. The `threadsPerGrid` parameter specifies the number of threads in the grid, and the `threadsPerThreadgroup` parameter specifies the number of threads in each threadgroup. The GPU will execute the compute function for each thread in the grid, with each threadgroup processing a block of the image.  



## Links
- I am following the course [Raytracing in one weekend](https://raytracing.github.io/books/RayTracingInOneWeekend.html)  
- [Apple sample code - Accelerating ray tracing and motion blur using Metal](https://developer.apple.com/documentation/metal/metal_sample_code_library/accelerating_ray_tracing_and_motion_blur_using_metal)  
- also following the book Metal by Tutorials -Razeware LLC (2019) by the raywenderlich Tutorial Team, Caroline Begbie, Marius Horga  
- The resources to the book : https://github.com/kodecocodes/met-materials/tree/editions/4.0/02-3d-models/projects/resources  
- Some Blender beginner tutorials https://www.kodeco.com/21459096-blender-tutorial-for-beginners-how-to-make-a-mushroom  
