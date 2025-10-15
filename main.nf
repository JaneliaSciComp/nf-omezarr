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
    def String command = "nextflow run ${workflow.manifest.name} --input /path/to/images --outdir ./output -profile singularity"
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

include { paramsSummaryLog; paramsSummaryMap } from 'plugin/nf-validation'

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
include { UNWRAP_SINGLE_IMAGE }         from './modules/local/unwrap/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './modules/nf-core/custom/dumpsoftwareversions/main'

workflow TO_OMEZARR {
    ch_versions = Channel.empty()

    // Define supported image file extensions (based on Bio-Formats)
    def supportedExtensions = [
        'tif', 'tiff', 'czi', 'lsm', 'nd2', 'oib', 'oif', 'lif', 'ims', 'vsi', 'scn', 'svs', 'ndpi',
        'dv', 'r3d', 'stk', 'pic', 'ome.tiff', 'ome.tif', 'lei', 'flex', 'mea', 'res', 'sld', 'aim',
        'al3d', 'gel', 'am', 'amiramesh', 'grey', 'hx', 'labels', 'cif', 'img', 'hdr', 'sif', 'png',
        'afi', 'htd', 'pnl', 'avi', 'arf', 'exp', 'spc', 'sdt', 'xml', 'h5', '1sc', 'raw', 'dcm',
        'dicom', 'v', 'eps', 'epsi', 'ps', 'fits', 'dm3', 'dm4', 'dm2', 'gif', 'naf', 'his', 'vms',
        'txt', 'bmp', 'jpg', 'i2i', 'ics', 'ids', 'fff', 'seq', 'ipw', 'hed', 'mod', 'liff', 'obf',
        'msr', 'xdce', 'frm', 'inr', 'ipl', 'ipm', 'dat', 'par', 'jp2', 'jpk', 'jpx', 'klb', 'xv',
        'bip', 'fli', 'l2d', 'lim', 'htd', 'mvd2', 'acff', 'wat', 'wlz', 'lms', 'zvi', 'mdb', 'mrxs',
        'mcd', 'sxm', 'tfr', 'ffr', 'zfr', 'zfp', '2fl', 'pr3', 'fdf', 'hdf', 'bif', 'dti', 'xys',
        'html', 'wat', 'pcx', 'pds', 'im3', 'pbm', 'pgm', 'ppm', 'psd', 'bin', 'pict', 'cfg', 'spe',
        'afm', 'mov', 'rcpnl', 'sm2', 'sm3', 'xqd', 'xqf', 'cxd', 'db', 'tga', 'vws', 'top', 'pcoraw',
        'rec', 'crw', 'cr2', 'ch5', 'c01', 'dib', 'nef', 'nii', 'nii.gz', 'nrrd', 'nhdr', 'omp2info',
        'apl', 'mtb', 'tnb', 'obsep', 'oir', 'pct', 'qptiff', 'tf2', 'tf8', 'btf', 'ome', 'sldy',
        'mrw', 'mng', 'stp', 'mrc', 'st', 'ali', 'map', 'mrcs', 'mnc', 'jdce'
    ]

    // Create a channel for image files
    Channel
        .fromPath(params.input)
        .map { inputPath ->
            def inputFile = new File(inputPath.toString())
            
            if (inputFile.isDirectory()) {
                // If input is a directory, find all image files
                def imageFiles = []
                inputFile.eachFileRecurse { file ->
                    if (file.isFile()) {
                        def extension = file.name.toLowerCase().split('\\.').last()
                        // Handle multi-part extensions like .ome.tiff
                        if (file.name.toLowerCase().contains('.ome.')) {
                            def parts = file.name.toLowerCase().split('\\.')
                            if (parts.size() >= 3) {
                                extension = "${parts[-2]}.${parts[-1]}"
                            }
                        }
                        if (supportedExtensions.contains(extension)) {
                            imageFiles.add(file.getAbsolutePath())
                        }
                    }
                }
                return imageFiles
            } else {
                // If input is a single file, check if it's a supported format
                def extension = inputFile.name.toLowerCase().split('\\.').last()
                if (inputFile.name.toLowerCase().contains('.ome.')) {
                    def parts = inputFile.name.toLowerCase().split('\\.')
                    if (parts.size() >= 3) {
                        extension = "${parts[-2]}.${parts[-1]}"
                    }
                }
                // Convert from org.codehaus.groovy.runtime.GStringImpl to String, so that comparisons work
                extension = extension.toString()
                if (supportedExtensions.contains(extension)) {
                    return [inputFile.getAbsolutePath()]
                } else {
                    log.error "Unsupported file format: ${inputFile.name}"
                    return []
                }
            }
        }
        .flatten()
        .map { imagePath ->
            def imageFile = new File(imagePath)
            def meta = [
                id: imageFile.name.replaceAll(/\.[^.]+$/, '') // Remove file extension for ID
            ]
            def memo_path = params.memo_dir ? params.memo_dir : params.outdir
            // Create memo directory if it doesn't exist
            new File(memo_path).mkdirs()
            [meta, imageFile.getAbsolutePath(), params.outdir, memo_path]
        }
        .filter {
            def meta = it[0]
            def zarrFilePath = "${params.outdir}/${meta.id}.zarr"
            if (new File(zarrFilePath).exists()) {
                log.debug "Zarr file already exists for ID '${meta.id}' at: ${zarrFilePath}"
                return false
            }
            return true
        }
        .set { ch_input }

    // Convert to OME-Zarr
    BIOFORMATS2RAW(ch_input.map {
        def (meta, image, abs_output_path, memo_path) = it
        [meta, image, abs_output_path, memo_path]
    })

    // Unwrap single-image outputs if requested
    if (params.unwrap) {
        UNWRAP_SINGLE_IMAGE(BIOFORMATS2RAW.out.params)
    }

    ch_versions = ch_versions.mix(BIOFORMATS2RAW.out.versions)
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
