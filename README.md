# Ray Tracing in one weekend with metal
A spin of the popular book series adapted for the power of Apple Silicon. 
I did a C version here: [Ray-Tracing-in-One-Weekend-in-C](https://github.com/multitudes/Ray-Tracing-in-One-Weekend-in-C) but i am curious to see how to reimplement this with Metal and learn Metal along the way. 

Metal was announced at the Worldwide Developers Conference (WWDC) on June 2, 2014, an Apple alternative to Direct3D (which is part of DirectX - Windows) and OpenGL. Apple created a new language to program the GPU directly via shader functions. This is the Metal Shading Language (MSL) based on the C++11 specification. A year later at WWDC15, Apple announced two Metal sub-frameworks: MetalKit and Metal Performance Shaders (MPS). You typically usse Metal to have access to the GPU. GPUs belong to a special class of computation called Single Instruction Multiple Data (SIMD) and optimized for throughput (how much data can be processed in one unit of time).   

The beauty of the book [Raytracing in one weekend](https://raytracing.github.io/books/RayTracingInOneWeekend.html) is that it doesnt use any libraries and instead writes to a ppm file which is a very easy to understand and text based format. To use a high level framework like metal for such basic tasks will be small challenge. I am curious to see the tradeoffs and the difference in speed between the twos.



## rendering models and pipelines
To get access to the power of the Apple GPU, typically the CPU creates a command buffer which will be passed to the GPU for rendering.  
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
