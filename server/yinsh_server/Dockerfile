# start Julia docker image
FROM julia:1.11.3

# name and create working directory
ENV workdir_name=/yinsh
WORKDIR ${workdir_name}

# copy selected files to destination (workdir)
COPY Project.toml Manifest.toml ${workdir_name}
COPY proto_logic.jl ${workdir_name}
RUN julia -t auto -e 'using Pkg; Pkg.activate("."); Pkg.instantiate()'

# expose port for communication
EXPOSE 6091

# run julia and file (we're already in workdir)
CMD julia -t auto proto_logic.jl