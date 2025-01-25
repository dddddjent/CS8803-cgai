# Explanation

My implementation is not based on the latest commit. It's based on f06dd3.
- So I had to modify page.tsx.

Some important data are from the external page.tsx, including the light positions and the transformation
for the objects.
- I implemented `sphere`, `box`, `cylinder`, `capsule` and `plane` sdfs.
- I also added some ops and smooth ops for sdfs.
- My actual objects use these sdfs to create shapes, and return an additional index to the materials.
    - So there's only one scene.
- Normals are calculated based on finite differences. See 167 - 174.
- Ray marching is at 191 - 207.
- Shading is at 220 - 234.
- Transformation is done by formulating the matrix first, and apply the inverse matrix.
    - This is at 130 - 146.
