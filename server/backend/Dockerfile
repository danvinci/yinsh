# start Julia docker image
FROM julia:1.9.3

# name and create working directory
ENV workdir_name=/yinsh
WORKDIR ${workdir_name}

# copy selected files to destination (workdir) 
COPY proto_logic.jl ${workdir_name}
RUN julia -t auto -e 'using Pkg; Pkg.add.(["Dates", "HTTP", "JSON3", "PlotThemes", "Plots", "PlutoUI", "Random", "StatsBase", "MbedTLS"]); Pkg.precompile()'

# expose port for communication
EXPOSE 6091

# run julia and file (we're already in workdir)
CMD julia -t auto proto_logic.jl