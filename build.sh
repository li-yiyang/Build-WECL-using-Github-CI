#!/usr/bin/env bash
# Building WECL with latest ECL
# This script is just a copy of
# https://turtleware.eu/posts/Common-Lisp-and-WebAssembly.html

##### Building ECL
git clone https://gitlab.com/embeddable-common-lisp/ecl.git
cd ecl
export ECL_SRC=`pwd`
export ECL_HOST=${ECL_SRC}/ecl-host
./configure --prefix=${ECL_HOST} && make -j`nproc` && make install

##### Install and activate emsdk
git clone https://github.com/emscripten-core/emsdk.git
pushd emsdk
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh
popd

##### Build the target version of ECL
make distclean # removes build/ directory
export ECL_WASM=${ECL_SRC}/ecl-wasm
export ECL_TO_RUN=${ECL_HOST}/bin/ecl
emconfigure ./configure --host=wasm32-unknown-emscripten --build=x86_64-pc-linux-gnu \
            --with-cross-config=${ECL_SRC}/src/util/wasm32-unknown-emscripten.cross_config \
            --prefix=${ECL_WASM} --disable-shared --with-tcp=no --with-cmp=no

emmake make -j`nproc` && emmake make install

# some files need to be copied manually
cp build/bin/ecl.js build/bin/ecl.wasm ${ECL_WASM}

##### Building WECL
fossil clone https://fossil.turtleware.eu/wecl
cd wecl

pushd Code
cp -r ${ECL_WASM} wasm-ecl
git clone https://github.com/dkochmanski/slime.git
popd

./make.sh build

##### Prepare files for release
# the webserver.lisp is added in release to avoid
# using python -m http.server, so that user can just
# use $LISP webserver.lisp to serve the files to
# test if the build success or not.
cp webserver.lisp App

# rename the WECL just to make the release files
# more pretty when user got their files.
mv App WECL
tar czf WECL.tar.gz WECL
cp WECL.tar.gz ~/
