#!/usr/bin/python3

# this scrpt creates a .obj mesh of a plane suited for viewing videos in opengl

import sys

lod = 16

if len(sys.argv) > 1:
    try:
        lod = int(sys.argv[1])
    except:
        print("Pass level of detail as first argument. default: {}", lod)
        exit()


vertices = []
uvs = []
faces = []

lodp = lod+1

for i in range(lodp * lodp):
    u = (i // lodp) / lod
    v = (i % lodp) / lod

    x = u*2 - 1
    y = v*2 - 1
    z = -1

    vertices.append((x,y,z))
    uvs.append((u, v))

    if i % lodp != 0 and i // lodp != 0:
        j = i + 1
        a = j
        b = a - 1
        c = a - lodp
        d = b - lodp
        faces.append(((a, a), (c, c), (b, b)))
        faces.append(((b, b), (c, c), (d, d)))


# print obj

for v in vertices:
    print("v", *v)

for uv in uvs:
    print("vt", *uv)

for f in faces:
    s = "f"
    for u in f:
        s += " " + "/".join(map(str, u))
    print(s)

