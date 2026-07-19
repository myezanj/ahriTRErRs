#!/usr/bin/env sh
set -eu

prefix="${1:-${AHRI_TRE_PREFIX:-}}"
if [ -z "$prefix" ]; then
    echo "usage: AHRI_TRE_PREFIX=/prefix ./install.sh or ./install.sh /prefix" >&2
    exit 2
fi

case "$prefix" in
    /*) ;;
    *)
        echo "AHRI_TRE_PREFIX must be an absolute path" >&2
        exit 2
        ;;
esac

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
runtime_dir="$prefix/libexec/ahri-tre"

mkdir -p "$prefix/bin" "$prefix/lib" "$prefix/include" "$prefix/share" "$runtime_dir"
cp -R "$script_dir/lib/." "$prefix/lib/"
cp -R "$script_dir/include/." "$prefix/include/"
mkdir -p "$prefix/share/ahri-tre"
cp -R "$script_dir/share/ahri-tre/." "$prefix/share/ahri-tre/"

install_runtime_binary() {
    name="$1"
    cp "$script_dir/bin/$name" "$runtime_dir/$name"
    chmod 755 "$runtime_dir/$name"
    cat > "$prefix/bin/$name" <<EOF
#!/usr/bin/env sh
set -eu
prefix=\${AHRI_TRE_PREFIX:-$prefix}
lib_dir="\$prefix/lib"
case "\$(uname -s)" in
    Darwin)
        if [ -n "\${DYLD_LIBRARY_PATH:-}" ]; then
            export DYLD_LIBRARY_PATH="\$lib_dir:\$DYLD_LIBRARY_PATH"
        else
            export DYLD_LIBRARY_PATH="\$lib_dir"
        fi
        ;;
    *)
        if [ -n "\${LD_LIBRARY_PATH:-}" ]; then
            export LD_LIBRARY_PATH="\$lib_dir:\$LD_LIBRARY_PATH"
        else
            export LD_LIBRARY_PATH="\$lib_dir"
        fi
        ;;
esac
exec "\$prefix/libexec/ahri-tre/$name" "\$@"
EOF
    chmod 755 "$prefix/bin/$name"
}

install_runtime_binary ahri-tre
install_runtime_binary ahri-tred

printf '%s\n' "Installed AHRI TRE runtime to $prefix"
