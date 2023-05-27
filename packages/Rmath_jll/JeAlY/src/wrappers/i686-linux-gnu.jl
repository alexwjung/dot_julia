# Autogenerated wrapper script for Rmath_jll for i686-linux-gnu
export libRmath

JLLWrappers.@generate_wrapper_header("Rmath")
JLLWrappers.@declare_library_product(libRmath, "libRmath-julia.so")
function __init__()
    JLLWrappers.@generate_init_header()
    JLLWrappers.@init_library_product(
        libRmath,
        "lib/libRmath-julia.so",
        RTLD_LAZY | RTLD_DEEPBIND,
    )

    JLLWrappers.@generate_init_footer()
end  # __init__()
