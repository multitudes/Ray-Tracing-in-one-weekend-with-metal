# Ray Tracing in one weekend with metal
A spin of the popular book series adapted for the power of Apple Silicon. 
I did a C version here: [Ray-Tracing-in-One-Weekend-in-C](https://github.com/multitudes/Ray-Tracing-in-One-Weekend-in-C) but i am curious to see how to reimplement this with Metal and learn Metal along the way. 

Metal was announced at the Worldwide Developers Conference (WWDC) on June 2, 2014, an Apple alternative to Direct3D (which is part of DirectX - Windows) and OpenGL. Apple created a new language to program the GPU directly via shader functions. This is the Metal Shading Language (MSL) based on the C++11 specification. A year later at WWDC15, Apple announced two Metal sub-frameworks: MetalKit and Metal Performance Shaders (MPS). You typically usse Metal to have access to the GPU. GPUs belong to a special class of computation called Single Instruction Multiple Data (SIMD) and optimized for throughput (how much data can be processed in one unit of time).   

The beauty of the book [Raytracing in one weekend](https://raytracing.github.io/books/RayTracingInOneWeekend.html) is that it doesnt use any libraries and instead writes to a ppm file which is a very easy to understand and text based format. To use a high level framework like metal for such basic tasks will be small challenge. I am curious to see the tradeoffs and the difference in speed between the twos.



## Rendering pipelines
To get access to the power of the Apple GPU, typically the CPU creates a command buffer which will be passed to the GPU for rendering.  
Metal works with pipelines for maximum efficiency.  
There are two main approaches to rendering graphics:

- A traditional pipeline model is a raster-model, which uses a rasterizer to color the pixels on the screen.  
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

- The raytracing model involves shooting rays from the camera, out of the screen and into the scene. In pseudocode:
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

In ideal conditions, light travels through the air as a ray following a straight line until it hits a surface.  
Once the ray hits something, any combination of the following: absorption, reflection, refraction, and scattering may occur.
• Light gets absorbed into the surface.
• Light gets reflected by the surface.
• Light gets refracted through the surface.
• Light gets scattered from another point under the surface.


We start by importing the MetalKit framework and creating a reference to our GPU. At the same time the code checks if a suitable GPU is found if not it will stop here.
```swift
import MetalKit

guard let device = MTLCreateSystemDefaultDevice() else {
  fatalError("GPU is not supported")
}
```



## Render a gradient

## Render a sphere




## Links
- I am following the course [Raytracing in one weekend](https://raytracing.github.io/books/RayTracingInOneWeekend.html)  
- [Apple sample code - Accelerating ray tracing and motion blur using Metal](https://developer.apple.com/documentation/metal/metal_sample_code_library/accelerating_ray_tracing_and_motion_blur_using_metal)  
- also following the book Metal by Tutorials -Razeware LLC (2019) by the raywenderlich Tutorial Team, Caroline Begbie, Marius Horga  
- The resources to the book : https://github.com/kodecocodes/met-materials/tree/editions/4.0/02-3d-models/projects/resources  
- Some Blender beginner tutorials https://www.kodeco.com/21459096-blender-tutorial-for-beginners-how-to-make-a-mushroom  
