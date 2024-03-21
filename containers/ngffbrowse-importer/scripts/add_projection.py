import os
import sys
import shutil
import zarr
from pathlib import Path

# First argument is a filepath to OME-Zarr
omezarr_filepath = sys.argv[1]

# Second argument is the filepath to a 2d projection to add
projection_filepath = sys.argv[2]

# Copy the projection into the OME-Zarr container
projection_filename = os.path.basename(projection_filepath)
projection_newpath = os.path.join(omezarr_filepath, "0", "projections", projection_filename)
print(f"Copying from {projection_filepath} to {projection_newpath}")
Path(projection_newpath).parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(projection_filepath, projection_newpath)
print("Done")

# Update the metadata to point to the projection
print("Updating OME-Zarr metadata")
with zarr.open(omezarr_filepath, mode='rw') as z:

    # This currently assumes that a single image was converted to OME-Zarr
    # format using bioformats2raw, so there is a series at the top level.
    image = z['0']

    if 'janelia' in image.attrs:
        raise Exception('Janelia metadata is already set for this image')

    image.attrs['janelia'] = {
        'projections' : {
            '0': { # multiscale dataset name, assume full scale
                'xy': 'projections/'+projection_filename
            }
        }
    }

print("Done")