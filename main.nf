#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    JaneliaSciComp/nf-omezarr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/JaneliaSciComp/nf-omezarr
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl=2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE & PRINT PARAMETER SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsHelp; validateParameters; } from 'plugin/nf-validation'

// Print help message if needed
if (params.help) {
    def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
    def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
    def String command = "nextflow run ${workflow.manifest.name} --input samplesheet.csv --outdir ./output -profile singularity"
    log.info logo + paramsHelp(command) + citation + NfcoreTemplate.dashedLine(params.monochrome_logs)
    System.exit(0)
}

// Validate input parameters
if (params.validate_params) {
    validateParameters()
}

def final_params = WorkflowMain.initialise(workflow, params, log)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryLog; paramsSummaryMap; fromSamplesheet } from 'plugin/nf-validation'

def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
def summary_params = paramsSummaryMap(workflow)

// Print parameter summary log to screen
log.info logo + paramsSummaryLog(workflow) + citation

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { BIOFORMATS2RAW              } from './modules/janelia/bioformats2raw/main'
include { NGFFBROWSEIMPORTER          } from './modules/janelia/ngffbrowseimporter/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './modules/nf-core/custom/dumpsoftwareversions/main'

workflow TO_OMEZARR {
    ch_versions = Channel.empty()

    Channel
        .fromSamplesheet("input")
        .map {
            def (meta, image, output_path, projection) = it

            def abs_output_path = params.outdir
            if (output_path && !output_path.isEmpty()) {
                abs_output_path = output_path
                if (!abs_output_path.startsWith('/')) {
                    abs_output_path = new File(params.outdir, output_path).getAbsolutePath()
                }
                abs_output_f = new File(abs_output_path)
                if (!abs_output_f.exists()) {
                    abs_output_f.mkdirs()
                }
            }

            def abs_projection = null
            if (projection && !projection.isEmpty()) {
                abs_projection = projection
                if (!abs_projection.startsWith('/')) {
                    abs_projection = new File(image.getParent(), projection)
                }
            }

            [meta, image, abs_output_path, abs_projection]
        }
        .set { ch_input }

    // Convert to OME-Zarr
    BIOFORMATS2RAW(ch_input.map {
        def (meta, image, abs_output_path, abs_projection) = it
        [meta, image, abs_output_path]
    })
    ch_versions = ch_versions.mix(BIOFORMATS2RAW.out.versions)

    // Join with the input to map zarr paths to projections
    zarrs = BIOFORMATS2RAW.out.params.join(ch_input).map {
        def (meta, image, zarr_path, image2, abs_output_path, abs_projection) = it
        [meta, zarr_path, abs_projection]
    }
    .filter { it[2] != null }

    // Assign projections to zarrs
    NGFFBROWSEIMPORTER(zarrs)
    ch_versions = ch_versions.mix(NGFFBROWSEIMPORTER.out.versions)

    //
    // MODULE: Pipeline reporting
    //
    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )
}

workflow {
    TO_OMEZARR()
}

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log)
    }
    NfcoreTemplate.dump_parameters(workflow, params)
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}
