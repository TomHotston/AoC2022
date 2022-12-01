{
    description = "A Rust development shell";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    };

    outputs = { self, nixpkgs }: let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in {
            devShell.x86_64-linux =
                pkgs.mkShell {
                    buildInputs = with pkgs; [
                        llvmPackages_latest.llvm
                        llvmPackages_latest.bintools
                        zlib.out
                        rustup
                        xorriso
                        grub2
                        qemu
                        llvmPackages_latest.lld

                        (python3.withPackages (p: with p; [
                            jupyterlab
                        ]))

                        pkg-config
                    ];
                    # https://github.com/rust-lang/rust-bindgen#environment-variables
                    LIBCLANG_PATH = pkgs.lib.makeLibraryPath [ pkgs.llvmPackages_latest.libclang.lib ];
                    shellHook = let
                        rust_ver = "stable-2022-09-22";
                    in ''
                        mkdir $PWD/.rustup
                        mkdir $PWD/.cargo
                        mkdir $PWD/.jupyter

                        export PATH=$PATH:$PWD/.cargo/bin
                        export PATH=$PATH:$PWD/.rustup/toolchains/$RUSTC_VERSION-x86_64-unknown-linux-gnu/bin/
                        export CARGO_HOME=$PWD/.cargo
                        export RUSTUP_HOME=$PWD/.rustup
                        export JUPYTER_PATH=$PWD/.jupyter

                        # Install rust
                        rustup toolchain install ${rust_ver}
                        rustup default ${rust_ver}
                        rustup component add rust-src --toolchain ${rust_ver}

                        # Install non-packaged
                        cargo install evcxr_jupyter
                        evcxr_jupyter --install
                    '';
                    # Add libvmi precompiled library to rustc search path
                    RUSTFLAGS = (builtins.map (a: ''-L ${a}/lib'') [
                    ]);
                    # Add libvmi, glibc, clang, glib headers to bindgen search path
                    BINDGEN_EXTRA_CLANG_ARGS =
                    # Includes with normal include path
                    (builtins.map (a: ''-I"${a}/include"'') [
                        pkgs.glibc.dev
                    ])
                        # Includes with special directory paths
                    ++ [
                        ''-I"${pkgs.llvmPackages_latest.libclang.lib}/lib/clang/${pkgs.llvmPackages_latest.libclang.version}/include"''
                        ''-I"${pkgs.glib.dev}/include/glib-2.0"''
                        ''-I${pkgs.glib.out}/lib/glib-2.0/include/''
                    ];
                };
        };
}
