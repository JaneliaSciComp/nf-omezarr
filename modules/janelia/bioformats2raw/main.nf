process BIOFORMATS2RAW {
    tag "${meta.id}"
    container "ghcr.io/janeliascicomp/bioformats2raw:0.9.2"
    cpus { task.ext.cpus }
    memory { task.ext.memory }

    input:
    tuple val(meta),
          path(input_image),
          path(output_path)

    output:
    tuple val(meta),
          path(input_image),
          path(zarr_output_path),
          emit: params
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    extra_args = task.ext.args ?: ''
    zarr_output_path = output_path.toString()+"/"+input_image.getBaseName()+".zarr"
    """
    /opt/bioformats2raw/bin/bioformats2raw \
        --max_workers=$task.cpus \
        $extra_args \
        $input_image \
        "$zarr_output_path"
        
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioformats2raw: \$(cat /opt/VERSION)
    END_VERSIONS
    """
}
