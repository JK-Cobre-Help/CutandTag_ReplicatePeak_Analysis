# CutandTag_ReplicatePeak_Analysis

![ReplicatePeaks](/images/replicatePeaks.png)
- OpenAI. (2024). Scientific data visualization: Replicate peak analysis in bioinformatics [AI-generated image]. DALL-E. Retrieved from ChatGPT interface.

# 1) Project Description

**CutAndTag_ReplicatePeak_Analysis** is a Snakemake pipeline designed to perform downstream analysis on processed Cut-and-Tag sequencing data. Rather than starting from raw FASTQ reads, this pipeline starts with already aligned and filtered BAM files, focusing on the identification of reproducible peaks, the generation of consensus peak sets, and the visualization of overlaps and signal distributions across multiple samples or experimental conditions.

+ Note: If you are starting from raw FASTQ files, consider using the [CutandTag_Analysis_Snakemake](https://github.com/JK-Cobre-Help/CutandTag_Analysis_Snakemake) pipeline first. That pipeline handles the initial data processing steps—such as quality control, alignment, and basic filtering—providing you with the cleaned and aligned data that serve as the input for CutAndTag_ReplicatePeak_Analysis.

## Key Features

- **Peak Calling with MACS2**:
  The pipeline calls peaks for each sample using MACS2, a widely-used tool for identifying enriched regions in sequencing data.

- **Merged and Consensus Peak Sets**:
  Using sample groupings defined in `samples.csv` (the "Set" column), peaks are merged to produce a comprehensive candidate region set. A consensus peak set is then generated by applying a reproducibility threshold (in the `config.yml`), ensuring that only peaks observed in a defined minimum number of samples are retained.

- **Consensus Peak Conversion**:
  Consensus peak sets are converted into BAM and BigWig formats, enabling efficient genome browser visualization and facilitating downstream analyses.

- **Euler Plots of Overlaps**:
  The pipeline creates Euler diagrams to represent the overlap of peaks among individual samples within a set. This visual approach reveals how consensus peaks emerge from the intersection of multiple replicates.

- **Midpoint and Overlap Analysis**:
  The pipeline identifies peak midpoints and quantifies overlaps, enabling an exploration of peak distribution and subtle differences or similarities of signal across all of the samples beds.

- **Heatmaps for Signal Distribution**:
  By using consensus peak midpoints, the pipeline generates heatmaps that visualize coverage patterns. These heatmaps provide insights into the intensity and distribution of signal across multiple conditions or sample sets.

# 2) Intended Use Case
This pipeline is ideal for researchers who have already processed their Cut-and-Tag data through preliminary steps such as quality control, alignment, and filtering (e.g., by using [CutandTag_Analysis_Snakemake](https://github.com/JK-Cobre-Help/CutandTag_Analysis_Snakemake)). After obtaining high-quality aligned BAM files, you can use CutAndTag_ReplicatePeak_Analysis to:

- Identify reproducible peaks across replicates or experimental conditions.
- Generate integrative visual summaries of peak overlaps.
- Compare signal intensity profiles around consensus peak midpoints.

By integrating this two-step approach, you ensure a robust, end-to-end workflow for your Cut-and-Tag sequencing experiments.

# 3) Dependencies and Configuration

All parameters (e.g., genome size, MACS2 q-values, minimum number of overlapping samples for consensus peaks, paths to executables) are controlled via the `config/config.yml` file.

## Explanation of `config.yml`
- Note. Make sure to check config.yml for the appropriate genome

The `config.yml` file controls genome settings, tool versions, and other workflow parameters.

## Changing Genomes
By default, the config.yml is set up for hs (human hg38). Running mouse (mm10) samples requires changing these values to match the mm10 parameters, which are already provided in `config.yml` as comments.

To switch from mm10 to hg38 (or vice versa), you’ll need to change:
- **Genome and Effective Genome Size**:
  Update genome and effective genomes sizes
  - For human (hg38), set `genome: "hs"` and `effective_genome_size: 2913022398`
  - For mouse (mm10), set `genome: "mm"` and `effective_genome_size: 2730871774`

- **Chrom_sizes File**:
  Point chrom_sizes to the correct chromosome sizes file.
  - For human (hg38), set `resources/hg38.chrom.sizes`
  - For mouse (mm10), set `resources/mm10.chrom.sizes`

All information required for switching between hg38 and mm10 is included in config.yml, commented out next to the default settings. Simply uncomment and modify these values as needed when changing the genome from mm10 to hg38.

Tool Versions and Modules
The `config.yml` file also specifies versions of tools and modules (e.g., deeptools, macs2, samtools, bedtools, R) used by the pipeline. These versions help maintain reproducibility and ensure that the pipeline runs consistently across different computing environments.

# 4) Tools & Modules
The pipeline relies on bioinformatics tools, including:

- **MACS2** for peak calling
- **bedtools** and samtools for peak and alignment format conversions
- **deeptools** for coverage and matrix computation, as well as for generating heatmaps
- **R** with **Bioconductor** packages for merging peaks, generating consensus sets, and creating **Euler** diagrams

# 5) Example Data
A compact, pre-processed dataset is included in this repository to quickly test the pipeline and validate that your environment is set up correctly. This small example replicates the pipeline’s key steps from peak calling through to final visualization.

# 6) Explanation of `samples.csv`
Note. Make sure to check sample.csv before each run

`samples.csv` specifies the samples to analyze, their BAM file locations, and how they are grouped into sets. The file has three columns: `sample`, `bam`, and `set`.

**Example `samples.csv`:**
```csv
sample,bam,set
Treatment_Rep1,resources/test1.bam,Set1
Treatment_Rep2,resources/test1A.bam,Set1
Treatment_Rep3,resources/test1B.bam,Set1
Control_Rep1,resources/input1.bam,Set2
Control_Rep2,resources/input1A.bam,Set2
Control_Rep3,resources/input2B.bam,Set2
```

**sample**: Unique sample name (used in output filenames)  
**bam**: Path to the aligned BAM file  
**set**: Sample grouping for consensus peak analysis

- All samples with the same **Set** name will be combined to generate a consensus peak set.

# 7) Instructions to run on Slurm managed HPC
2A. Clone repository
```
git clone https://github.com/JK-Cobre-Help/CutandTag_ReplicatePeak_Analysis.git
```
2B. Load modules
```
module purge
module load slurm python/3.10 pandas/2.2.3 numpy/1.22.3 matplotlib/3.7.1
```
2C. Modify samples and config file
```
vim samples.csv
vim config.yml
```
2D. Dry Run
```
snakemake -npr
```
2E. Run on HPC with config.yml options
```
sbatch --wrap="snakemake -j 999 --use-envmodules --latency-wait 60 --cluster-config config/cluster_config.yml --cluster 'sbatch -A {cluster.account} -p {cluster.partition} --cpus-per-task {cluster.cpus-per-task}  -t {cluster.time} --mem {cluster.mem} --output {cluster.output}'"
```

