export PREBUILT=$ANDROID_NDK/toolchains/arm-linux-androideabi-4.6/prebuilt
export PLATFORM=$ANDROID_NDK/platforms/android-8/arch-arm 
export PREFIX=/home/a/Downloads/x264/build
./configure --prefix=$PREFIX \
--enable-static \
--enable-pic \
--disable-asm \
--disable-cli \
--host=arm-linux \
--cross-prefix=$PREBUILT/linux-x86/bin/arm-linux-androideabi- \
--sysroot=$PLATFORM
