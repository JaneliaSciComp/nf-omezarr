# OME-Zarr Conversion Pipeline

This Nextflow pipeline automates the conversion of [Bio-Formats-compatible images](https://bio-formats.readthedocs.io/en/v8.3.0/supported-formats.html) into the [Next Generation File Format (NGFF)](https://github.com/ome/ngff) (a.k.a. OME-Zarr) using [bioformats2raw](https://github.com/glencoesoftware/bioformats2raw). 

## Why use this pipeline instead of bioformats2raw directly?

While you can absolutely run bioformats2raw on its own or use the excellent [NGFF-Converter](https://github.com/glencoesoftware/NGFF-Converter) GUI, this pipeline has advantages in certain situtations:

* **HPC Integration**: Easily schedules and distributes work on high-performance computing (HPC) clusters.
* **Dependency Encapsulation**: No need to install or manage Java, Blosc, or other libraries. Everything runs in a controlled, containerized environment.
* **Batch Processing**: Automatically scans and processes entire directories of images.
* **Extended Features**: Includes Janelia-specific enhancements that may also benefit other users and facilities.

## Quick Start

The only software requirements for running this pipeline are [Nextflow](https://www.nextflow.io) (version 23.04.0 or greater) and either [Docker](https://docs.docker.com/get-started/get-docker/) or [Singularity/Apptainer](https://apptainer.org/). If you are running on an HPC cluster, ask your system administrator to install Apptainer on all the cluster nodes.

To [install Nextflow](https://www.nextflow.io/docs/latest/getstarted.html):

    curl -s https://get.nextflow.io | bash 

Alternatively, you can install it as a conda package:

    conda create --name nextflow -c bioconda nextflow

You can [install Apptainer](https://apptainer.org/docs/user/latest/quick_start.html#installation) by following the instructions for your platform.

Now you can run the pipeline and it will download everything else it needs. Simply specify either a single image file or a directory containing image files.

**For a single image file:**
```bash
    nextflow run JaneliaSciComp/nf-omezarr -profile singularity \
        --input /path/to/image.czi --outdir ./output 
```

**For a directory containing multiple images:**
```bash
    nextflow run JaneliaSciComp/nf-omezarr -profile singularity \
        --input /path/to/images/ --outdir ./output 
```

The pipeline automatically detects all [Bioformats-compatible image files](https://docs.openmicroscopy.org/bio-formats/5.8.2/supported-formats.html) in the specified directory and processes each one. Supported formats include CZI, TIFF, LSM, ND2, LIF, IMS, VSI, and many others.

By default, the Zarr chunk size is set to 128,128,128. You can customize the chunk size of the zarr using the `--chunk_size` parameter, e.g.

```bash
    nextflow run JaneliaSciComp/nf-omezarr -profile singularity \
        --input /path/to/images/ --outdir ./output --chunk_size 1920,1920,1 
```

The pipeline defaults to Blosc compression using LZ4 at compression level 6, which is the best all-around compression that we have found works for most types of microscopy data. You can customize this with the `--compression` and `--compression_properties` options. 

This pipeline is [nf-core](https://nf-co.re/)-compatible and reuses pipeline infrastructure from the nf-core project, including the ability to use [nf-core institutional profiles](https://nf-co.re/configs/) that let you run on many university clusters without additional configuration. For example, to run this pipeline on the Janelia cluster, simply specify the Janelia profile: 

```bash
    nextflow run JaneliaSciComp/nf-omezarr -profile janelia \
         --input /path/to/images/ --outdir ./output
```

## Pipeline options 
 
Define the input data and bioformats2raw parameters. 
 
| Parameter | Description | Type | Default | Required | Hidden | 
|-----------|-----------|-----------|-----------|-----------|-----------| 
| `input` | Path to input image file or directory containing image files to convert. <details><summary>Help</summary><small>Provide either a single image file in any Bioformats-compatible format, or a directory containing multiple image files. If a directory is provided, all supported image files within it will be processed.</small></details>| `string` | | True | | 
| `outdir` | The output directory where the results will be saved. You have to use absolute paths to storage on Cloud infrastructure. | `string` | | True | | 
| `memo_dir` | The directory where the temporary memo files will be saved. Default: outdir/tmp | `string` | | | True | 
| `chunk_size` | Chunk size for Zarr in X,Y,Z order. Default: 128,128,128 | `string` | | | | 
| `compression` | How the blocks will be compressed. Default: blosc | `string` | blosc | | | 
| `compression_properties` | Comma-delimited compression properties for the blocks. Default: cname=lz4,clevel=6 | `string` | cname=lz4,clevel=6 | | | 
| `overwrite` | Overwrite images in the output directory if they exists. Default: false | `boolean` | | | | 
| `bioformats2raw_opts` | Extra options for Bioformats2raw | `string` | | | | 
| `unwrap` | Unwrap single-image outputs by moving contents of '0' directory up one level. Default: true | `string` | True | | | 
| `cpus` | Number of cores to allocate for bioformats2raw. Default: 10 | `integer` | | | | 
| `memory` | Amount of memory to allocate for bioformats2raw. Default: 36.G | `string` | | | | 
 


