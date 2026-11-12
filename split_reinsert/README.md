# FASTA splitting and k-mer counting workflow

This workflow extracts the first `TEST_BP` bases of a FASTA, starting at its
first contig and continuing across contigs as needed. It splits the sequence
into FASTA records of `CHROMOSOME_SIZE`, validates the output, compresses it
with bgzip, and counts k-mers with Meryl.

## Project files and inputs

Keep these files together in `split_reinsert_test/`:

- `test_file_splitting.sh` — Slurm batch script.
- `reinsert_headers.py` — splits headerless sequence into FASTA records.
- `environment.yml` — Conda/Mamba environment definition. It names the
  environment `splitting_env`.

The script's default input is:

```text
/data/senthilkumars2/Anniella_stebbinsi_HiFi_2024.asm.hic.hap1.fasta.gz
```

Change the `INPUT` default in the script or pass an input path when submitting.
The input must be BGZF-compressed for indexed extraction. `samtools faidx` in 
the batch script creates the `.fai` index and, for BGZF input, the `.gzi` index 
beside the input file. 

## Setup and job submission

1. Connect to Biowulf and start an interactive session. 


2. Initialize Conda/Mamba using your account's setup. If `myconda` is your
   setup script:

   ```bash
   source myconda
   ```

3. Change to the project directory. Submitting from here lets the script find
   `reinsert_headers.py` and puts the default durable output directory here.

   ```bash
   cd /path/to/split_reinsert_test
   ```

4. Create and activate the environment:

   ```bash
   mamba env create -f environment.yml
   mamba activate splitting_env
   ```

   `mamba env create` gets the environment name from the `name:` field in
   `environment.yml`; no separate name option is needed.


5. Submit the job script with `sbatch test_file_splitting.sh`, or specify additional parameters.

Example job submission that sets input file path, processes the first 50 Mb, and sets the chromosome size to 2 Mb:

   ```bash
   sbatch --export=ALL,INPUT=/path/to/genome.fasta.gz,TEST_BP=50000000,CHROMOSOME_SIZE=2000000 \
     test_file_splitting.sh
   ```

   To override the input path, set `INPUT` as in the example or edit its
   default in the script. 
   
   `TEST_BP` is a positive integer number of bases. If it is unset or empty,
   the script uses the total sequence length from the FASTA index and processes
   the whole genome. 

   `CHROMOSOME_SIZE` is a positive integer number of bases. 

   
   `PYTHON_SCRIPT` defaults to `$SLURM_SUBMIT_DIR/reinsert_headers.py`; therefore submit from the project
   directory or explicitly set `PYTHON_SCRIPT` to the helper's path.

## Parameters and resources

| Setting | Default | Description |
|---|---:|---|
| Slurm CPUs | 8 | Used for bgzip and Meryl threads |
| Slurm memory | 24 GB | Total memory requested from Slurm |
| Slurm local scratch | 100 GB | Requested with `--gres=lscratch:100` |
| Slurm time | 20 hours | Maximum job runtime |
| `TEST_BP` | Whole FASTA | Number of bases to extract; unset/empty means all bases |
| `CHROMOSOME_SIZE` | 1,000,000 | Bases per generated FASTA record |
| `K` | 28 | Meryl k-mer size |
| `MERYL_MEMORY` | 6 GB | Meryl memory limit; leave headroom within the Slurm memory request |

Adjust the `#SBATCH` directives in the script or pass corresponding options to
`sbatch`. For example, `sbatch --cpus-per-task=8 --mem=24G
--gres=lscratch:100 --time=20:00:00 test_file_splitting.sh`. The selected
number of Slurm CPUs sets both `BGZIP_THREADS` and `MERYL_THREADS`.

## Directory layout

`SLURM_SUBMIT_DIR` is the directory from which `sbatch` is run. By default,
the script uses it as `DURABLE_ROOT`; the job's durable output directory is
`$DURABLE_ROOT/$SLURM_JOB_ID`. `WORKDIR` defaults to `${LSCRATCH:-/lscratch/$SLURM_JOB_ID}/scratch_output`.

Example when submitting from `split_reinsert_test/`:

```text
split_reinsert_test/                         # SLURM_SUBMIT_DIR / DURABLE_ROOT
├── README.md
├── environment.yml
├── reinsert_headers.py
├── test_file_splitting.sh
├── splitting-test-JOBID.out                  # Slurm standard output
├── splitting-test-JOBID.err                  # Slurm standard error
└── JOBID/                                   # Durable directory
    ├── firstTEST_BPbp.reinserted.fa.gz
    ├── firstTEST_BPbp.meryl/                # Meryl database directory
    ├── bgzip.time
    └── meryl.time

/lscratch/JOBID/scratch_output/              # Temporary WORKDIR
├── firstTEST_BPbp.fa                        # Extracted FASTA
├── firstTEST_BPbp.reinserted.fa             # Reinserted FASTA
├── firstTEST_BPbp.reinserted.fa.gz          # Compressed FASTA
├── firstTEST_BPbp.meryl/                    # Meryl database
├── bgzip.time
└── meryl.time

/path/to/input/genome.fasta.gz
/path/to/input/genome.fasta.gz.fai            # FASTA index
/path/to/input/genome.fasta.gz.gzi            # BGZF index
```

The script copies the compressed FASTA, Meryl database, and timing reports to
the durable directory after a successful run. The extracted and reinserted
uncompressed FASTAs remain in scratch. Scratch is temporary and may be removed
after the job ends; retain the durable copy of any results you need.

## Inputs and outputs

| Kind | File or pattern | Location | Purpose |
|---|---|---|---|
| Input | `*.fasta.gz` | Path set by `INPUT` | Source genome; must support BGZF indexed extraction |
| Index | `*.fasta.gz.fai`, `*.fasta.gz.gzi` | Beside input | FASTA and BGZF indexes used by `samtools faidx` |
| Input | `reinsert_headers.py` | Submission directory by default | Generates chunked FASTA records |
| Input | `environment.yml` | Project directory | Declares Python 3.11, samtools, seqkit, htslib, and Meryl |
| Intermediate | `firstTEST_BPbp.fa` | Scratch `WORKDIR` | Extracted sequence |
| Intermediate | `firstTEST_BPbp.reinserted.fa` | Scratch `WORKDIR` | FASTA with generated headers |
| Output | `firstTEST_BPbp.reinserted.fa.gz` | Scratch, then durable directory | bgzip-compressed FASTA |
| Output | `firstTEST_BPbp.meryl/` | Scratch, then durable directory | Meryl k-mer database |
| Report | `bgzip.time`, `meryl.time` | Scratch, then durable directory | `/usr/bin/time -v` reports for bgzip and Meryl |
| Slurm logs | `splitting-test-JOBID.out`, `splitting-test-JOBID.err` | Submission directory | Job standard output and error |

## Anniella resource and runtime reference

The following measurements are from successful job `35514905`, which processed
the full Anniella assembly. They are a reference from one run, not a runtime
or resource guarantee.

| Measurement | Observed value |
|---|---:|
| Bases processed | 1,886,126,331 |
| Output records | 1,887 at 1,000,000 bases per record |
| Slurm allocation | 8 CPUs, 24 GB RAM, 100 GB local scratch, 20 hours |
| Meryl parameters | `k=28`, `memory=6`, `threads=8` |
| Scratch `WORKDIR` size near final copy | 15 GB |
| bgzip elapsed time | 47 seconds |
| Meryl elapsed time | 2 minutes 36 seconds |
| Meryl maximum resident memory | About 6.1 GB |

The timing reports cover bgzip and Meryl only, not the entire workflow. The
15 GB scratch reading is a point-in-time measurement near the end, not a
measured peak. Runtime and scratch use vary with the input genome size and 
memory/compute node allocation. For a new genome, begin with a smaller `TEST_BP`, then use
`bgzip.time`, `meryl.time`, and the `Scratch usage before copying results`
section of the `.out` log to help determine resources needed for the full run.
