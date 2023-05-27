# Autogenerated wrapper script for ZeroMQ_jll for x86_64-w64-mingw32-cxx03
export libzmq

using libsodium_jll
JLLWrappers.@generate_wrapper_header("ZeroMQ")
JLLWrappers.@declare_library_product(libzmq, "libzmq.dll")
function __init__()
    JLLWrappers.@generate_init_header(libsodium_jll)
    JLLWrappers.@init_library_product(
        libzmq,
        "bin\\libzmq.dll",
        RTLD_LAZY | RTLD_DEEPBIND,
    )

    JLLWrappers.@generate_init_footer()
end  # __init__()
