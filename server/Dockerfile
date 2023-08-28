# start Julia docker image
FROM julia:1.9.3

ENV workdir_name=/yinsh_service
WORKDIR ${workdir_name}

# copy selected files to destination (workdir)
COPY proto_logic.jl ${workdir_name}
RUN julia -t auto -e 'using Pkg; Pkg.add.(["Dates", "HTTP", "JSON3", "PlotThemes", "Plots", "PlutoUI", "Random", "StatsBase"]); Pkg.precompile()'

# expose port for communication
EXPOSE 8090 443

# run julia and file (we're already in workdir)
CMD julia -t auto proto_logic.jl