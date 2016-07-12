# obj2binary
Parse a 3d object file format: Wavefront's obj file by Bison and Flex. And save vertex, texture coord, and normal as a binary file for OpenGL.

obj2binary can parse the obj file as the triangle data.  It only take care four commands, "v vt vn f".

I Use the Bison and Flex (yacc) for doing the parsing because I just want practice the skill of bison.

The idea how to parse an obj is from https://sourceforge.net/projects/objloaderforand/files/

I am making an Android 3D app.  I install the objLoader mentioned above.  However the parsing speed in java is aweful.  Thus I make my own parser, and save vertexes data in binary.  Now, I can read it very fast.  And the binary file zip size is also smaller than obj's zip size.

