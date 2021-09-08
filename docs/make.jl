using VectorMathOptInterface
using Documenter

DocMeta.setdocmeta!(VectorMathOptInterface, :DocTestSetup, :(using VectorMathOptInterface); recursive=true)

makedocs(;
    modules=[VectorMathOptInterface],
    authors="Manuel Berkemeier",
    repo="https://github.com/manuelbb-upb/VectorMathOptInterface.jl/blob/{commit}{path}#{line}",
    sitename="VectorMathOptInterface.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://manuelbb-upb.github.io/VectorMathOptInterface.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/manuelbb-upb/VectorMathOptInterface.jl",
)
