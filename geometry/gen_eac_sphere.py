#!/usr/bin/python3

# this scrpt creates a .obj mesh of a sphere suited for a equirectangular cubemap
# like those used in youtube's 360° videos
# uses opengl coordinates
# visible from the inside (TODO: make this a command line argument)

import sys
from math import sqrt, pi, asin

lod = 48

if len(sys.argv) > 1:
    try:
        lod = int(sys.argv[1])
    except:
        print("Pass level of detail as first argument. default: {}", lod)
        exit()


def norm(x,y,z):
    l = sqrt(x*x + y*y + z*z)
    return (x/l, y/l, z/l)

vertices = []
normals = []
uvs = []
faces = []

## eac format:
# top row: left, front, right
# buttom row: bottom, back, up

lodp = lod+1

# left
x = -1
for i in range(lodp*lodp):
    u = (i // lodp) / lod
    v = (i % lodp) / lod
    z = asin((u-0.5) * sqrt(2)) * 4/pi
    y = asin((v-0.5) * sqrt(2)) * 4/pi

    vertices.append(norm(x,y,z))
    normals.append(norm(-x,-y,-z))
    uvs.append(((1 - u) / 3, (1 + v) / 2))

    if i % lodp != 0 and i // lodp != 0:
        j = i + 1 + lodp*lodp*0
        a = j
        b = a - 1
        c = a - lodp
        d = b - lodp
        faces.append(((a, a, a), (b, b, b), (c, c, c)))
        faces.append(((b, b, b), (d, d, d), (c, c, c)))
# front
z = -1
for i in range(lodp*lodp):
    u = (i // lodp) / lod
    v = (i % lodp) / lod
    x = asin((u-0.5) * sqrt(2)) * 4/pi
    y = asin((v-0.5) * sqrt(2)) * 4/pi

    vertices.append(norm(x,y,z))
    normals.append(norm(-x,-y,-z))
    uvs.append(((1 + u) / 3, (1 + v) / 2))

    if i % lodp != 0 and i // lodp != 0:
        j = i + 1 + lodp*lodp*1
        a = j
        b = a - 1
        c = a - lodp
        d = b - lodp
        faces.append(((a, a, a), (c, c, c), (b, b, b)))
        faces.append(((b, b, b), (c, c, c), (d, d, d)))
# right
x = 1
for i in range(lodp*lodp):
    u = (i // lodp) / lod
    v = (i % lodp) / lod
    z = asin((u-0.5) * sqrt(2)) * 4/pi
    y = asin((v-0.5) * sqrt(2)) * 4/pi

    vertices.append(norm(x,y,z))
    normals.append(norm(-x,-y,-z))
    uvs.append(((2 + u) / 3, (1 + v) / 2))

    if i % lodp != 0 and i // lodp != 0:
        j = i + 1 + lodp*lodp*2
        a = j
        b = a - 1
        c = a - lodp
        d = b - lodp
        faces.append(((a, a, a), (c, c, c), (b, b, b)))
        faces.append(((b, b, b), (c, c, c), (d, d, d)))

# bottom
y = -1
for i in range(lodp*lodp):
    u = (i // lodp) / lod
    v = (i % lodp) / lod
    x = asin((u-0.5) * sqrt(2)) * 4/pi
    z = asin((v-0.5) * sqrt(2)) * 4/pi

    vertices.append(norm(x,y,z))
    normals.append(norm(-x,-y,-z))
    uvs.append(((0 + v) / 3, (u + 0) / 2))

    if i % lodp != 0 and i // lodp != 0:
        j = i + 1 + lodp*lodp*3
        a = j
        b = a - 1
        c = a - lodp
        d = b - lodp
        faces.append(((a, a, a), (b, b, b), (c, c, c)))
        faces.append(((b, b, b), (d, d, d), (c, c, c)))
# back
z = 1
for i in range(lodp*lodp):
    u = (i // lodp) / lod
    v = (i % lodp) / lod
    x = asin((u-0.5) * sqrt(2)) * 4/pi
    y = asin((v-0.5) * sqrt(2)) * 4/pi

    vertices.append(norm(x,y,z))
    normals.append(norm(-x,-y,-z))
    uvs.append(((1 + v) / 3, (u + 0) / 2))

    if i % lodp != 0 and i // lodp != 0:
        j = i + 1 + lodp*lodp*4
        a = j
        b = a - 1
        c = a - lodp
        d = b - lodp
        faces.append(((a, a, a), (b, b, b), (c, c, c)))
        faces.append(((b, b, b), (d, d, d), (c, c, c)))

# top
y = 1
for i in range(lodp*lodp):
    u = (i // lodp) / lod
    v = (i % lodp) / lod
    x = asin((u-0.5) * sqrt(2)) * 4/pi
    z = asin((v-0.5) * sqrt(2)) * 4/pi

    vertices.append(norm(x,y,z))
    normals.append(norm(-x,-y,-z))
    uvs.append(((3 - v) / 3, (u + 0) / 2))

    if i % lodp != 0 and i // lodp != 0:
        j = i + 1 + lodp*lodp*5
        a = j
        b = a - 1
        c = a - lodp
        d = b - lodp
        faces.append(((a, a, a), (c, c, c), (b, b, b)))
        faces.append(((b, b, b), (c, c, c), (d, d, d)))


# print obj

for v in vertices:
    print("v", *v)

for n in normals:
    print("vn", *n)

for uv in uvs:
    print("vt", *uv)

for f in faces:
    s = "f"
    for u in f:
        s += " " + "/".join(map(str, u))
    print(s)

