#!/bin/sh
cd thirdparty/godot-videodecoder/
gcc src/gdnative_videodecoder.c -I godot_include/ -I ffmpeg-static/ -lavcodec -lswresample -lavutil -lavformat -lswscale -fPIC -shared -o libgdnative_videodecoder.so
mkdir -p ../../addons/bin/x11
mv libgdnative_videodecoder.so ../../addons/bin/x11
cp videodecoder.gdnlib ../../addons/
cd ../..
