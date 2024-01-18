# start Julia docker image
FROM julia:1.10

# name and create working directory
ENV workdir_name=/yinsh
WORKDIR ${workdir_name}

# copy selected files to destination (workdir) 
# prod packages only (dev packages in commented line)
COPY proto_logic.jl ${workdir_name}
RUN julia -t auto -e 'using Pkg; Pkg.add.(["Dates", "HTTP", "JSON3", "Random", "Combinatorics", "StatsBase"]);'
# RUN julia -t auto -e 'using Pkg; Pkg.add.(["PlotThemes", "Plots", "PlutoUI"]);'

# expose port for communication
EXPOSE 6091

# run julia and file (we're already in workdir)
CMD julia -t auto proto_logic.jl