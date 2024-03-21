# OME-Zarr Converter 

Nextflow pipeline that converts Bioformats-compatible images to [NGFF](https://github.com/ome/ngff) (e.g. OME-Zarr) images using [bioformats2raw](https://github.com/glencoesoftware/bioformats2raw). Also generates metadata for [ngffbrowse](https://github.com/JaneliaSciComp/ngffbrowse).

## Quick Start

The only software requirements for running this pipeline are [Nextflow](https://www.nextflow.io) (version 20.10.0 or greater) and either Docker or [Singularity](https://sylabs.io) (version 3.5 or greater). If you are running in an HPC cluster, ask your system administrator to install Singularity on all the cluster nodes.

To [install Nextflow](https://www.nextflow.io/docs/latest/getstarted.html):

    curl -s https://get.nextflow.io | bash 

Alternatively, you can install it as a conda package:

    conda create --name nextflow -c bioconda nextflow

To [install Singularity](https://sylabs.io/guides/3.7/admin-guide/installation.html) on CentOS Linux:

    sudo yum install singularity

Now you can run the pipeline and it will download everything else it needs. First, prepare a samplesheet with your input data that looks as follows:

samplesheet.csv:

```
id,image,output_path,projection_xy
image1,/path/to/image1.czi,subpath,/path/to/image1_mip.png
image2,/path/to/image2.czi,subpath,/path/to/image2_mip.png
image2,/path/to/image3.czi,subpath,/path/to/image3_mip.png
```

Each row represents one input image in any Bioformats-compatible format (Zeiss CZI in the example above). The `output_path` is relative to the `--outdir` parameter and can be left empty. The `projection_xy` is likewise optional and should point to a MIP or thumbnail of the image. If provided, it will be included in the output Zarr container, and used for display in [ngffbrowse](https://github.com/JaneliaSciComp/ngffbrowse).

The following command will analyze one input image in N5 format and save a CSV of detected spots to the `./output` directory. 

    nextflow run JaneliaSciComp/nf-omezarr -profile singularity --input samplesheet.csv --outdir ./output --compression zlib --cpus 40

By default, the Zarr chunk size is set to 128,128,128. You can customize the chunk size of the zarr using the `--chunk_size` parameter, e.g.

    nextflow run JaneliaSciComp/nf-omezarr -profile singularity --input samplesheet.csv --outdir ./output --chunk_size 1920,1920,1 

This pipeline is [nf-core](https://nf-co.re/) compatible and reuses pipeline infrastructure from the nf-core projec, including the ability to use nf-core institutional profiles. 

## Pipeline options

Define the input data and bioformats2raw parameters.

| Parameter | Description | Type | Default | Required | Hidden |
|-----------|-----------|-----------|-----------|-----------|-----------|
| `input` | Path to comma-separated file containing information about the samples in the experiment. <details><summary>Help</su
| `outdir` | The output directory where the results will be saved. You have to use absolute paths to storage on Cloud infrastru
| `bioformats2raw_opts` | Extra options for Bioformats2raw | `string` |  |  |  |
| `chunk_size` | Chunk size for Zarr in X,Y,Z order. Default: 128,128,128 | `string` |  |  |  |
| `compression` | How the blocks will be compressed. Default: blosc | `string` |  |  |  |
| `cpus` | Number of cores to allocate for bioformats2raw. Default: 10 | `integer` |  |  |  |
| `memory` | Amount of memory to allocate for bioformats2raw. Default: 36.G | `string` |  |  |  |

## Institutional config options

Parameters used to describe centralised config profiles. These should not be edited.

| Parameter | Description | Type | Default | Required | Hidden |
|-----------|-----------|-----------|-----------|-----------|-----------|
| `custom_config_version` | Git commit id for Institutional configs. | `string` | master |  | True |
| `custom_config_base` | Base directory for Institutional configs. <details><summary>Help</summary><small>If you're running off
| `config_profile_name` | Institutional config name. | `string` |  |  | True |
| `config_profile_description` | Institutional config description. | `string` |  |  | True |
| `config_profile_contact` | Institutional config contact information. | `string` |  |  | True |
| `config_profile_url` | Institutional config URL link. | `string` |  |  | True |

## Max job request options

Set the top limit for requested resources for any single job.

| Parameter | Description | Type | Default | Required | Hidden |
|-----------|-----------|-----------|-----------|-----------|-----------|
| `max_cpus` | Maximum number of CPUs that can be requested for any single job. <details><summary>Help</summary><small>Use to s
| `max_memory` | Maximum amount of memory that can be requested for any single job. <details><summary>Help</summary><small>Use
| `max_time` | Maximum amount of time that can be requested for any single job. <details><summary>Help</summary><small>Use to s

## Generic options

Less common options for the pipeline, typically set in a config file.

| Parameter | Description | Type | Default | Required | Hidden |
|-----------|-----------|-----------|-----------|-----------|-----------|
| `help` | Display help text. | `boolean` |  |  | True |
| `version` | Display version and exit. | `boolean` |  |  | True |
| `email` | Email address for completion summary. <details><summary>Help</summary><small>Set this parameter to your e-mail addr
| `email_on_fail` | Email address for completion summary, only when pipeline fails. <details><summary>Help</summary><small>An e
| `plaintext_email` | Send plain-text email instead of HTML. | `boolean` |  |  | True |
| `monochrome_logs` | Do not use coloured log outputs. | `boolean` |  |  | True |
| `hook_url` | Incoming hook URL for messaging service <details><summary>Help</summary><small>Incoming hook URL for messaging s
| `validate_params` | Boolean whether to validate parameters against the schema at runtime | `boolean` | True |  | True |
| `validationShowHiddenParams` | Show all params when using `--help` <details><summary>Help</summary><small>By default, paramet
| `validationFailUnrecognisedParams` | Validation of parameters fails when an unrecognised parameter is found. <details><summar
| `validationLenientMode` | Validation of parameters in lenient more. <details><summary>Help</summary><small>Allows string valu
