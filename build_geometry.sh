#!/bin/sh
cd geometry

python3 gen_half_sphere.py > half_sphere.obj
python3 gen_plane.py > plane.obj
python3 gen_sphere.py > sphere.obj
python3 gen_eac_sphere.py > eac_sphere.obj

cd ..
