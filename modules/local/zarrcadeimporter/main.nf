process ZARRCADEIMPORTER {
    tag "${meta.id}"
    container "ghcr.io/janeliascicomp/zarrcade-importer:0.0.1"
    
    input:
    tuple val(meta),
          path(zarr_path),
          path(projection_path)

    output:
    tuple val(meta),
          path(zarr_path),
          emit: params
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    extra_args = task.ext.args ?: ''
    """
    /app.sh add_projection \
        $zarr_path \
        $projection_path \
        $extra_args 
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        zarrcade_importer: \$(cat /app/VERSION)
    END_VERSIONS
    """
}
