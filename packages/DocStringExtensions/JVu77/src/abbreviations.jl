
#
# Abstract Interface.
#

"""
Abbreviation objects are used to automatically generate context-dependent markdown content
within documentation strings. Objects of this type interpolated into docstrings will be
expanded automatically before parsing the text to markdown.

$(:FIELDS)
"""
abstract type Abbreviation end

"""
$(:SIGNATURES)

Expand the [`Abbreviation`](@ref) `abbr` in the context of the `DocStr` `doc` and write
the resulting markdown-formatted text to the `IOBuffer` `buf`.
"""
format(abbr, buf, doc) = error("`format` not implemented for `$typeof(abbr)`.")

# Only extend `formatdoc` once with our abstract type. Within the package use a different
# `format` function instead to keep things decoupled from `Base` as much as possible.
Docs.formatdoc(buf::IOBuffer, doc::Docs.DocStr, part::Abbreviation) = format(part, buf, doc)


#
# Implementations.
#


#
# `TypeFields`
#

"""
The type for [`FIELDS`](@ref) abbreviations.

$(:FIELDS)
"""
struct TypeFields <: Abbreviation
    types::Bool
end

"""
An [`Abbreviation`](@ref) to include the names of the fields of a type as well as any
documentation that may be attached to the fields.

# Examples

The generated markdown text should look similar to to following example where a
type has three fields (`x`, `y`, and `z`) and the last two have documentation
attached.

```markdown

  - `x`

  - `y`

    Unlike the `x` field this field has been documented.

  - `z`

    Another documented field.
```
"""
const FIELDS = TypeFields(false)

"""
Identical to [`FIELDS`](@ref) except that it includes the field types.

# Examples

The generated markdown text should look similar to to following example where
a type has three fields; `x` of type `String`, `y` of type `Int`, and `z` of
type `Vector{Any}`.

```markdown

  - `x::String`

  - `y::Int`: Unlike the `x` field this field has been documented.

  - `z::Array{Any, 1}`: Another documented field.
```
"""
const TYPEDFIELDS = TypeFields(true)

function format(abbrv::TypeFields, buf, doc)
    local docs = get(doc.data, :fields, Dict())
    local binding = doc.data[:binding]
    local object = Docs.resolve(binding)
    local fields = isabstracttype(object) ? Symbol[] : fieldnames(object)
    if !isempty(fields)
        println(buf)
        for field in fields
            print(buf, "  - `", field)
            abbrv.types && print(buf, "::", fieldtype(object, field))
            print(buf, "`")
            # Print the field docs if they exist and aren't a `doc"..."` docstring.
            if haskey(docs, field) && isa(docs[field], AbstractString)
                print(buf, ": ")
                indented = true
                for line in split(docs[field], "\n")
                    println(buf, indented || isempty(line) ? "" : "    ", rstrip(line))
                    indented = false
                end
            else
                println(buf)
            end
            println(buf)
        end
        println(buf)
    end
    return nothing
end


#
# `ModuleExports`
#

"""
The singleton type for [`EXPORTS`](@ref) abbreviations.

$(:FIELDS)
"""
struct ModuleExports <: Abbreviation end

"""
An [`Abbreviation`](@ref) to include all the exported names of a module is a sorted list of
`Documenter.jl`-style `@ref` links.

!!! note

    The names are sorted alphabetically and ignore leading `@` characters so that macros are
    *not* sorted before other names.

# Examples

The markdown text generated by the `EXPORTS` abbreviation looks similar to the following:

```markdown

  - [`bar`](@ref)
  - [`@baz`](@ref)
  - [`foo`](@ref)

```
"""
const EXPORTS = ModuleExports()

function format(::ModuleExports, buf, doc)
    local binding = doc.data[:binding]
    local object = Docs.resolve(binding)
    local exports = names(object)
    if !isempty(exports)
        println(buf)
        # Sorting ignores the `@` in macro names and sorts them in with others.
        for sym in sort(exports, by = s -> lstrip(string(s), '@'))
            # Skip the module itself, since that's always exported.
            sym === nameof(object) && continue
            # We print linked names using Documenter.jl cross-reference syntax
            # for ease of integration with that package.
            println(buf, "  - [`", sym, "`](@ref)")
        end
        println(buf)
    end
    return nothing
end


#
# `ModuleImports`
#

"""
The singleton type for [`IMPORTS`](@ref) abbreviations.

$(:FIELDS)
"""
struct ModuleImports <: Abbreviation end

"""
An [`Abbreviation`](@ref) to include all the imported modules in a sorted list.

# Examples

The markdown text generated by the `IMPORTS` abbreviation looks similar to the following:

```markdown

  - `Foo`
  - `Bar`
  - `Baz`

```
"""
const IMPORTS = ModuleImports()

function format(::ModuleImports, buf, doc)
    local binding = doc.data[:binding]
    local object = Docs.resolve(binding)
    local imports = unique(ccall(:jl_module_usings, Any, (Any,), object))
    if !isempty(imports)
        println(buf)
        for mod in sort(imports, by = string)
            println(buf, "  - `", mod, "`")
        end
        println(buf)
    end
end


#
# `MethodList`
#

"""
The singleton type for [`METHODLIST`](@ref) abbreviations.

$(:FIELDS)
"""
struct MethodList <: Abbreviation end

"""
An [`Abbreviation`](@ref) for including a list of all the methods that match a documented
`Method`, `Function`, or `DataType` within the current module.

# Examples

The generated markdown text will look similar to the following example where a function
`f` defines two different methods (one that takes a number, and the other a string):

````markdown
```julia
f(num)
```

defined at [`<path>:<line>`](<github-url>).

```julia
f(str)
```

defined at [`<path>:<line>`](<github-url>).
````
"""
const METHODLIST = MethodList()

function format(::MethodList, buf, doc)
    local binding = doc.data[:binding]
    local typesig = doc.data[:typesig]
    local modname = doc.data[:module]
    local func = Docs.resolve(binding)
    local groups = methodgroups(func, typesig, modname; exact = false)
    if !isempty(groups)
        println(buf)
        for group in groups
            println(buf, "```julia")
            for method in group
                printmethod(buf, binding, func, method)
                println(buf)
            end
            println(buf, "```\n")
            if !isempty(group)
                local method = group[1]
                local file = string(method.file)
                local line = method.line
                local path = cleanpath(file)
                local URL = url(method)
                isempty(URL) || println(buf, "defined at [`$path:$line`]($URL).")
            end
            println(buf)
        end
        println(buf)
    end
    return nothing
end


#
# `MethodSignatures`
#

"""
The singleton type for [`SIGNATURES`](@ref) abbreviations.

$(:FIELDS)
"""
struct MethodSignatures <: Abbreviation end

"""
An [`Abbreviation`](@ref) for including a simplified representation of all the method
signatures that match the given docstring. See [`printmethod`](@ref) for details on
the simplifications that are applied.

# Examples

The generated markdown text will look similar to the following example where a function `f`
defines method taking two positional arguments, `x` and `y`, and two keywords, `a` and the `b`.

````markdown
```julia
f(x, y; a, b...)
```
````
"""
const SIGNATURES = MethodSignatures()

function format(::MethodSignatures, buf, doc)
    local binding = doc.data[:binding]
    local typesig = doc.data[:typesig]
    local modname = doc.data[:module]
    local func = Docs.resolve(binding)
    local groups = methodgroups(func, typesig, modname)

    if !isempty(groups)
        println(buf)
        println(buf, "```julia")
        for group in groups
            for method in group
                printmethod(buf, binding, func, method)
                println(buf)
            end
        end
        println(buf, "\n```\n")
    end
end


#
# `TypedMethodSignatures`
#

"""
The singleton type for [`TYPEDSIGNATURES`](@ref) abbreviations.

$(:FIELDS)
"""
struct TypedMethodSignatures <: Abbreviation end

"""
An [`Abbreviation`](@ref) for including a simplified representation of all the method
signatures with types that match the given docstring. See [`printmethod`](@ref) for details on
the simplifications that are applied.

# Examples

The generated markdown text will look similar to the following example where a function `f`
defines method taking two positional arguments, `x` and `y`, and two keywords, `a` and the `b`.

````markdown
```julia
f(x::Int, y::Int; a, b...)
```
````
"""
const TYPEDSIGNATURES = TypedMethodSignatures()

function format(::TypedMethodSignatures, buf, doc)
    local binding = doc.data[:binding]
    local typesig = doc.data[:typesig]
    local modname = doc.data[:module]
    local func = Docs.resolve(binding)
    # TODO: why is methodgroups returning invalid methods?
    # the methodgroups always appears to return a Vector and the size depends on whether parametric types are used
    # and whether default arguments are used
    local groups = methodgroups(func, typesig, modname)
    if !isempty(groups)
        group = groups[end]
        println(buf)
        println(buf, "```julia")
        for (i, method) in enumerate(group)
            N = length(arguments(method))
            # return a list of tuples that represent type signatures
            tuples = find_tuples(typesig)
            # The following will find the tuple that matches the number of arguments in the function
            # ideally we would check that the method signature matches the Tuple{...} signature
            # but that is not straightforward because of how expressive Julia can be
            function f(t)
                if t isa DataType
                    return t <: Tuple && length(t.types) == N
                elseif t isa UnionAll
                    return f(t.body)
                else
                    return false
                end
            end

            @static if Sys.iswindows() && VERSION < v"1.8"
                t = tuples[findlast(f, tuples)]
            else
                t = tuples[findfirst(f, tuples)]
            end
            printmethod(buf, binding, func, method, t)
            println(buf)
        end
        println(buf, "\n```\n")
    end
end

#
# `FunctionName`
#

"""
The singleton type for [`FUNCTIONNAME`](@ref) abbreviations.

$(:FIELDS)
"""
struct FunctionName <: Abbreviation end

"""
An [`Abbreviation`](@ref) for including the function name matching the method of
the docstring.

# Usage

This is mostly useful for not repeating the function name in docstrings where
the user wants to retain full control of the argument list, or the latter does
not exist (eg generic functions).

Note that the generated docstring snippet is not quoted, use indentation or
explicit quoting.

# Example

```julia
\"""
    \$(FUNCTIONNAME)(d, θ)

Calculate the logdensity `d` at `θ`.

Users should define their own methods for `$(FUNCTIONNAME)`.
\"""
function logdensity end
```
"""
const FUNCTIONNAME = FunctionName()

format(::FunctionName, buf, doc) = print(buf, doc.data[:binding].var)

#
# `TypeSignature`
#

"""
The singleton type for [`TYPEDEF`](@ref) abbreviations.
"""
struct TypeDefinition <: Abbreviation end

"""
An [`Abbreviation`](@ref) for including a summary of the signature of a type definition.
Some of the following information may be included in the output:

  * whether the object is an `abstract` type or a `bitstype`;
  * mutability (either `type` or `struct` is printed);
  * the unqualified name of the type;
  * any type parameters;
  * the supertype of the type if it is not `Any`.

# Examples

The generated output for a type definition such as:

```julia
\"""
\$(TYPEDEF)
\"""
struct MyType{S, T <: Integer} <: AbstractArray
    # ...
end
```

will look similar to the following:

````markdown
```julia
struct MyType{S, T<:Integer} <: AbstractArray
```
````

!!! note

    No information about the fields of the type is printed. Use the [`FIELDS`](@ref)
    abbreviation to include information about the fields of a type.
"""
const TYPEDEF = TypeDefinition()

function print_supertype(buf, object)
    super = supertype(object)
    super != Any && print(buf, " <: ", super)
end

function print_params(buf, object)
    if !isempty(object.parameters)
        print(buf, "{")
        join(buf, object.parameters, ", ")
        print(buf, "}")
    end
end

function print_primitive_type(buf, object)
    print(buf, "primitive type ", object.name.name)
    print_supertype(buf, object)
    print(buf, " ", sizeof(object) * 8)
    println(buf)
end

function print_abstract_type(buf, object)
    print(buf, "abstract type ", object.name.name)
    print_params(buf, object)
    print_supertype(buf, object)
    println(buf)
end

function print_mutable_struct_or_struct(buf, object)
    ismutabletype(object) && print(buf, "mutable ")
    print(buf, "struct ", object.name.name)
    print_params(buf, object)
    print_supertype(buf, object)
    println(buf)
end

function format(::TypeDefinition, buf, doc)
    local binding = doc.data[:binding]
    local object = gettype(Docs.resolve(binding))
    if isa(object, DataType)
        println(buf, "\n```julia")
        if isprimitivetype(object)
            print_primitive_type(buf, object)
        elseif isabstracttype(object)
            print_abstract_type(buf, object)
        else
            print_mutable_struct_or_struct(buf, object)
        end
        println(buf, "```\n")
    end
end

"""
The singleton type for [`README`](@ref) abbreviations.
"""
struct Readme <: Abbreviation end
"""
    README

An [`Abbreviation`](@ref) for including the package README.md.

!!! note
    The README.md file is interpreted as ["Julia flavored Markdown"]
    (https://docs.julialang.org/en/v1/manual/documentation/#Markdown-syntax-1),
    which has some differences compared to GitHub flavored markdown, and,
    for example, [][] link shortcuts are not supported.
"""
const README = Readme()
"""
The singleton type for [`LICENSE`](@ref) abbreviations.
"""
struct License <: Abbreviation end
"""
    LICENSE

An [`Abbreviation`](@ref) for including the package LICENSE.md.

!!! note
    The LICENSE.md file is interpreted as ["Julia flavored Markdown"]
    (https://docs.julialang.org/en/v1/manual/documentation/#Markdown-syntax-1),
    which has some differences compared to GitHub flavored markdown, and,
    for example, [][] link shortcuts are not supported.
"""
const LICENSE = License()

function format(::T, buf, doc) where T <: Union{Readme,License}
    m = get(doc.data, :module, nothing)
    m === nothing && return
    path = pathof(m)
    path === nothing && return
    try # wrap in try/catch since we shouldn't error in case some IO operation goes wrong
        r = T === Readme ? r"(?i)readme(?-i)" : r"(?i)license(?-i)"
        # assume README/LICENSE is located in the root of the repo
        root = normpath(joinpath(path, "..", ".."))
        for file in readdir(root)
            if occursin(r, file)
                str = read(joinpath(root, file), String)
                write(buf, str)
                return
            end
        end
    catch
    end
end


#
# `DocStringTemplate`
#

"""
The singleton type for [`DOCSTRING`](@ref) abbreviations.
"""
struct DocStringTemplate <: Abbreviation end

"""
An [`Abbreviation`](@ref) used in [`@template`](@ref) definitions to represent the location
of the docstring body that should be spliced into a template.

!!! warning

    This abbreviation must only ever be used in template strings; never normal docstrings.
"""
const DOCSTRING = DocStringTemplate()

# NOTE: no `format` needed for this 'mock' abbreviation.

is_docstr_template(::DocStringTemplate) = true
is_docstr_template(other) = false

"""
Internal abbreviation type used to wrap templated docstrings.

`Location` is a `Symbol`, either `:before` or `:after`. `dict` stores a
reference to a module's templates.
"""
struct Template{Location} <: Abbreviation
    dict::Dict{Symbol,Vector{Any}}
end

function format(abbr::Template, buf, doc)
    # Find the applicable template based on the kind of docstr.
    parts = get_template(abbr.dict, template_key(doc))
    # Replace the abbreviation with either the parts of the template found
    # before the `DOCSTRING` abbreviation, or after it. When no `DOCSTRING`
    # exists in the template, which shouldn't really happen then nothing will
    # get included here.
    for index in included_range(abbr, parts)
        # We don't call `DocStringExtensions.format` here since we need to be
        # able to format any content in docstrings, rather than just
        # abbreviations.
        Docs.formatdoc(buf, doc, parts[index])
    end
end

function included_range(abbr::Template, parts::Vector)
    # Select the correct indexing depending on what we find.
    build_range(::Template, ::Nothing) = 0:-1
    build_range(::Template{:before}, index) = 1:(index - 1)
    build_range(::Template{:after}, index) = (index + 1):lastindex(parts)
    # Search for index from either the front or back.
    find_index(::Template{:before}) = findfirst(is_docstr_template, parts)
    find_index(::Template{:after}) = findlast(is_docstr_template, parts)
    # Find and return the correct indices.
    return build_range(abbr, find_index(abbr))
end

function template_key(doc::Docs.DocStr)
    # Local helper methods for extracting the template key from a docstring.
    ismacro(b::Docs.Binding) = startswith(string(b.var), '@')
    objname(obj::Union{Function,Module,DataType,UnionAll,Core.IntrinsicFunction}, b::Docs.Binding) = nameof(obj)
    objname(obj, b::Docs.Binding) = Symbol("") # Empty to force resolving to `:CONSTANTS` below.
    # Select the key returned based on input argument types.
    _key(::Module, sig, binding)                 = :MODULES
    _key(::Function, ::typeof(Union{}), binding) = ismacro(binding) ? :MACROS : :FUNCTIONS
    _key(::Function, sig, binding)               = ismacro(binding) ? :MACROS : :METHODS
    _key(::DataType, ::typeof(Union{}), binding) = :TYPES
    _key(::UnionAll, ::typeof(Union{}), binding) = :TYPES
    _key(::DataType, sig, binding)               = :METHODS
    _key(other, sig, binding)                    = :DEFAULT

    binding = doc.data[:binding]
    obj = Docs.resolve(binding)
    name = objname(obj, binding)
    key = name === binding.var ? _key(obj, doc.data[:typesig], binding) : :CONSTANTS
    return key
end