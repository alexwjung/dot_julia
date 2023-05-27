# Use baremodule to shave off a few KB from the serialized `.ji` file
baremodule Cubature_jll
using Base
using Base: UUID
import JLLWrappers

JLLWrappers.@generate_main_file_header("Cubature")
JLLWrappers.@generate_main_file("Cubature", UUID("7bc98958-0e37-5d67-a6ac-a3a19030071a"))
end  # module Cubature_jll
