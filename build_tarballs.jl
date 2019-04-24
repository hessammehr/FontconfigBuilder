# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Fontconfig"
version = v"2.13.1-0"

# Collection of sources required to build Fontconfig
sources = [
    "https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.1.tar.gz" =>
    "9f0d852b39d75fc655f9f53850eb32555394f36104a044bb2b2fc9e66dbbfa7f",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
if [[ $target == *"linux"* ]]; then
    wget "https://github.com/hessammehr/UtilLinuxBuilder/releases/download/v2.33.0/UtilLinuxBuilder.v2.33.0.$target.tar.gz"
    tar xzf UtilLinuxBuilder*.tar.gz --directory $prefix
fi
wget https://github.com/hessammehr/GperfBuilder/releases/download/v3.1.0-0/Gperf.v3.1.0.x86_64-linux-gnu.tar.gz
tar xzf Gperf*.tar.gz --directory $prefix

cd $prefix/lib/pkgconfig/

if [ ! -f zlib.pc ]; then
(cat <<EOF
prefix=/workspace/destdir
exec_prefix=${prefix}
libdir=${exec_prefix}/lib
sharedlibdir=${libdir}
includedir=${prefix}/include

Name: zlib
Description: zlib compression library
Version: 1.2.11

Requires:
Libs: -L${libdir} -L${sharedlibdir} -lz
Cflags: -I${includedir}
EOF
) > zlib.pc
fi

(cat <<EOF
prefix=/workspace/destdir
exec_prefix=${prefix}
libdir=${exec_prefix}/lib
sharedlibdir=${libdir}
includedir=${prefix}/include

Name: bzip2
Description: bzip2 compression library
Version: 1.0.6

Requires:
Libs: -L${libdir} -L${sharedlibdir} -lbz2
Cflags: -I${includedir}
EOF
) > bzip2.pc

sed -i 's/2.9.1/22.1.16/g' freetype2.pc
cd $WORKSPACE/srcdir/fontconfig-2.13.1/
./configure --prefix=$prefix --host=$target
sed -i 's/\/uuid//g' test/Makefile
make
make install


if [ $target = "x86_64-unknown-freebsd11.1" ]; then
cd $WORKSPACE/srcdir
cd $prefix/lib/pkgconfig/
ls
cd ..
ls
cd pkgconfig/

fi

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]

# The products that we will ensure are always built
products(prefix) = [
    ExecutableProduct(prefix, "fc-validate", :fc_validate),
    LibraryProduct(prefix, "libfontconfig", :libfontconfig),
    ExecutableProduct(prefix, "fc-cat", :fc_cat),
    ExecutableProduct(prefix, "fc-conflist", :fc_conflist),
    ExecutableProduct(prefix, "fc-match", :fc_match),
    ExecutableProduct(prefix, "fc-pattern", :fc_pattern),
    ExecutableProduct(prefix, "fc-scan", :fc_scan),
    ExecutableProduct(prefix, "fc-list", :fc_list),
    ExecutableProduct(prefix, "fc-cache", :fc_cache),
    ExecutableProduct(prefix, "fc-query", :fc_query)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/hessammehr/ExpatBuilder/releases/download/v2.2.6/build_ExpatBuilder.v2.2.6.jl",
    "https://github.com/JuliaGraphics/FreeTypeBuilder/releases/download/v2.9.1-2/build_FreeType2.v2.9.1.jl",
    "https://github.com/staticfloat/Bzip2Builder/releases/download/v1.0.6-1/build_Bzip2.v1.0.6.jl",
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.4/build_Zlib.v1.2.11.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

