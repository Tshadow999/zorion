# Zorion Engine

Using zig to make a game engine. 

Will feature the following at some point:
- 2d and 3d rendering
- 2d and 3d Physics
- UI to interact with engine


## Building the engine
Use zig 0.13.0

Then use the command `zig build` to create an exe in the zig-out/bin directory.
Or use `zig build run-{exampledir}` to imediately run the executable from the examples

## Making more games
Create a new directory inside `examples/` and add your `main.zig` file.
Then to run: `zig build run-{game}`

## Dependencies

- [Mach](https://machengine.org/) for glfw, openGL and math
- [stb_image](https://github.com/nothings/stb/blob/master/stb_image.h) for texture rendering
- [Prototype generator](https://verythieflike.itch.io/prototype-texture-generator) for the prototype texture
