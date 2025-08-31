process BIOFORMATS2RAW {
    tag "${meta.id}"
    container "ghcr.io/janeliascicomp/bioformats2raw:0.10.1"
    cpus { task.ext.cpus }
    memory { task.ext.memory }

    input:
    tuple val(meta),
          path(input_image),
          path(output_path),
          path(memo_directory, stageAs: 'memo/*')
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
    max_workers = extra_args.contains("--max-workers") ? "" : "--max-workers=$task.cpus"
    memo_id = UUID.randomUUID().toString().substring(0,10)
    """
    # Generate random sequence of 10 chars for memo directory name
    MEMO_PATH="${memo_directory}/${memo_id}"
    mkdir -p \$MEMO_PATH
    echo "Created memo path: \$MEMO_PATH"

    function cleanup() {
        echo "Cleaning up memo directory \$MEMO_PATH"
        rm -rf \$MEMO_PATH
        exit 0
    }
    trap cleanup INT TERM EXIT

    /opt/bioformats2raw/bin/bioformats2raw \
        --memo-directory \$MEMO_PATH \
        $max_workers \
        $extra_args \
        $input_image \
        "$zarr_output_path"
        
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioformats2raw: \$(cat /opt/VERSION)
    END_VERSIONS
    """
}
