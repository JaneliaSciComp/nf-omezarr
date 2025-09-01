
// Process to unwrap single-image outputs
process UNWRAP_SINGLE_IMAGE {
    tag "${meta.id}"
    
    input:
    tuple val(meta),
          path(input_image),
          path(zarr_output_path)
    
    output:
    tuple val(meta),
          path(input_image),
          path(zarr_output_path),
          emit: unwrapped
    
    script:
    """
    # Check if zarr output contains only '0' directory and no '1' directory
    if [ -d "${zarr_output_path}/0" ] && [ ! -d "${zarr_output_path}/1" ]; then
        echo "Single image detected in ${zarr_output_path}, unwrapping..."
        
        mv "${zarr_output_path}/0" "${zarr_output_path}/image"

        # Move all contents from 0/ up one level, including hidden files
        mv "${zarr_output_path}/image/"* "${zarr_output_path}/" 2>/dev/null || true
        mv "${zarr_output_path}/image/".* "${zarr_output_path}/" 2>/dev/null || true

        # Remove the now empty image directory
        rmdir "${zarr_output_path}/image"

        echo "Unwrapping completed for ${zarr_output_path}"
    else
        echo "Multiple images detected or no '0' directory found in ${zarr_output_path}, skipping unwrap"
    fi
    """
}