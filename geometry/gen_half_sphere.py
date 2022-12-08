#!/usr/bin/python3

# this scrpt creates a .obj mesh of a half-sphere suited for viewing 180° videos in opengl

import sys
from math import sqrt, sin, cos, pi

lod = 64

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

lodp = lod+1

for i in range(lodp * lodp):
    u = (i // lodp) / lod
    v = (i % lodp) / lod

    y = sin((v-0.5)*pi)
    a = sqrt(1 - y*y)
    angle = u*pi
    z = -sin(angle) * a
    x = -cos(angle) * a

    vertices.append((x,y,z))
    normals.append((-x, -y, -z))
    uvs.append((u, v))

    if i % lodp != 0 and i // lodp != 0:
        j = i + 1
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

