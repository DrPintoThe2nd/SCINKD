#!/usr/bin/env bash
#SBATCH --job-name=splitting-test
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --gres=lscratch:100 
#SBATCH --time=20:00:00
#SBATCH --output=splitting-test-%j.out
#SBATCH --error=splitting-test-%j.err

set -euo pipefail

#Set file paths and parameters, allowing overrides from environment variables

# Replace /data/senthilkumars2/... with the path to your input FASTA file if different
INPUT="${INPUT:-/data/senthilkumars2/Anniella_stebbinsi_HiFi_2024.asm.hic.hap1.fasta.gz}"

#Path defaults to reinsert_headers.py in the same directory as the SLURM submission script
PYTHON_SCRIPT="${PYTHON_SCRIPT:-$SLURM_SUBMIT_DIR/reinsert_headers.py}"

#Durable root is where the final outputs will be copied to, such as the compressed FASTA, Meryl output, and timing reports. 
#Defaults to the SLURM submission directory if not specified.
DURABLE_ROOT="${DURABLE_ROOT:-$SLURM_SUBMIT_DIR}"

#Workdir is where the test files will be created in the scratch directory, 
#such as the extracted FASTA, reinserted FASTA, and timing reports (which will be copied to the durable root directory). 
WORKDIR="${WORKDIR:-${LSCRATCH:-/lscratch/$SLURM_JOB_ID}/scratch_output}"

#Durable_dir is where the final outputs will be copied to in the durable root directory, such as the compressed FASTA, Meryl output, and timing reports 
DURABLE_DIR="${JOB_OUTPUT_DIR:-$DURABLE_ROOT/$SLURM_JOB_ID}"

TEST_BP="${TEST_BP:-}" # can specify the number of bases to extract for testing. if not specified, the script will use the total length of the genome.
CHROMOSOME_SIZE="${CHROMOSOME_SIZE:-1000000}" #1 Mb chromosomes
K="${K:-28}"

BGZIP_THREADS="$SLURM_CPUS_PER_TASK" # bgzip can use all available threads
MERYL_THREADS="$SLURM_CPUS_PER_TASK" # meryl can use all available threads 
MERYL_MEMORY="${MERYL_MEMORY:-6}"

mkdir -p "$WORKDIR" # for scratch files

# Check for required commands and files
for command in samtools seqkit bgzip gzip meryl python awk grep cmp; do
    command -v "$command" >/dev/null || {
        echo "ERROR: command not found: $command" >&2
        exit 1
    }
done

[[ -f "$INPUT" ]] || {
    echo "ERROR: input FASTA not found: $INPUT" >&2
    exit 1
}

#look for .fai index in the same directory as the input FASTA, or in the current working directory if the input FASTA is a relative path.
#create .fai index and .gzi if it doesn't exist. 
if [[ ! -f "${INPUT}.fai" ]]; then
    echo "FASTA index not found; creating: ${INPUT}.fai"
    samtools faidx "$INPUT"
fi

[[ -f "${INPUT}.fai" ]] || {
    echo "ERROR: failed to create FASTA index: ${INPUT}.fai" >&2
    exit 1
}

#set TEST_BP to the total length of the genome if not specified
if [[ -z "$TEST_BP" ]]; then
    TEST_BP="$(awk -F '\t' '{total += $2} END {printf "%.0f\n", total}' "${INPUT}.fai")"
    echo "Using whole-genome length from FASTA index: $TEST_BP bases"
fi

# Validate that the Python script exists
[[ -f "$PYTHON_SCRIPT" ]] || {
    echo "ERROR: Python script not found: $PYTHON_SCRIPT" >&2
    exit 1
}

# Validate TEST_BP and CHROMOSOME_SIZE
[[ "$TEST_BP" =~ ^[1-9][0-9]*$ ]] || {
    echo "ERROR: TEST_BP must be a positive integer" >&2
    exit 1
}
[[ "$CHROMOSOME_SIZE" =~ ^[1-9][0-9]*$ ]] || {
    echo "ERROR: CHROMOSOME_SIZE must be a positive integer" >&2
    exit 1
}

# Create output files
EXTRACTED="$WORKDIR/first${TEST_BP}bp.fa"
REINSERTED="$WORKDIR/first${TEST_BP}bp.reinserted.fa"
COMPRESSED="$WORKDIR/first${TEST_BP}bp.reinserted.fa.gz"
MERYL_OUT="$WORKDIR/first${TEST_BP}bp.meryl"

echo "Input: $INPUT"
echo "Bases: $TEST_BP"
echo "Record size: $CHROMOSOME_SIZE"
echo "CPUs: $SLURM_CPUS_PER_TASK"



# Extract TEST_BP bases starting at the first contig in the FASTA, continuing across subsequent contigs as needed.
remaining=$TEST_BP
: > "$EXTRACTED"

# Read the FASTA index from its first entry until we reach TEST_BP or run out of sequence.
while IFS=$'\t' read -r name length _; do
    if (( remaining == 0 )); then
        break
    fi

    take=$(( length < remaining ? length : remaining )) # if the contig length is smaller than the remaining bases, we take the whole contig. if the contig length is larger than the remaining bases, we take only the remaining bases.
    if (( take > 0 )); then
        samtools faidx "$INPUT" "${name}:1-${take}" >> "$EXTRACTED" 
        remaining=$(( remaining - take ))
    fi
done < "${INPUT}.fai"

# Validate that we have extracted the requested number of bases
if (( remaining > 0 )); then
    echo "ERROR: FASTA does not contain enough sequence to extract $TEST_BP bases from its first contig onward" >&2
    exit 1
fi

test -s "$EXTRACTED"



# Wrap and remove headers in a stream, then split the sequence into chunks of CHROMOSOME_SIZE, and reinsert headers with the specified prefix. The output is written to REINSERTED.
echo "Wrapping, splitting, and reinserting headers"
seqkit seq -w 80 "$EXTRACTED" \
    | grep -v '^>' \
    | python "$PYTHON_SCRIPT" \
    --prefix "test" \
    --chromosome-size "$CHROMOSOME_SIZE" \
    --line-width 80 \
    > "$REINSERTED"

test -s "$REINSERTED"
seqkit seq -v "$REINSERTED" > /dev/null

# Validate that the total number of bases matches the expected TEST_BP
TOTAL_BP="$(awk '!/^>/ {total += length($0)} END {print total + 0}' "$REINSERTED")"
HEADER_COUNT="$(grep -c '^>' "$REINSERTED")"
EXPECTED_HEADERS=$(( (TOTAL_BP + CHROMOSOME_SIZE - 1) / CHROMOSOME_SIZE ))

if [[ "$HEADER_COUNT" -ne "$EXPECTED_HEADERS" ]]; then
    echo "ERROR: expected $EXPECTED_HEADERS headers, found $HEADER_COUNT" >&2
    exit 1
fi

# Validate that sequence lines are at most 80 bases
if awk '!/^>/ && length($0) > 80 {exit 1}' "$REINSERTED"; then
    echo "Validated: sequence lines are at most 80 bases"
else
    echo "ERROR: sequence line exceeds 80 bases" >&2
    exit 1
fi

# Validate that the total number of bases matches the expected TEST_BP
# In python, compare the sequences in two FASTA files, ignoring headers and line breaks. Exit with an error if they differ.

echo "Comparing sequence before and after processing"
python - "$EXTRACTED" "$REINSERTED" <<'PY'

import sys

def sequence_chunks(path):
    with open(path, "rb") as fasta:
        for line in fasta:
            if not line.startswith(b">"):
                sequence = line.rstrip(b"\r\n")
                if sequence:
                    yield sequence


left_chunks = iter(sequence_chunks(sys.argv[1]))
right_chunks = iter(sequence_chunks(sys.argv[2]))
left = next(left_chunks, None)
right = next(right_chunks, None)
left_offset = right_offset = 0

while left is not None and right is not None:
    length = min(len(left) - left_offset, len(right) - right_offset)
    if left[left_offset:left_offset + length] != right[right_offset:right_offset + length]:
        sys.exit("ERROR: sequences differ")

    left_offset += length
    right_offset += length
    if left_offset == len(left):
        left = next(left_chunks, None)
        left_offset = 0
    if right_offset == len(right):
        right = next(right_chunks, None)
        right_offset = 0

if left is not None or right is not None:
    sys.exit("ERROR: sequences differ in length")
PY

# Compress the reinserted FASTA file with bgzip and validate the compression
echo "Compressing with bgzip"
/usr/bin/time -v -o "$WORKDIR/bgzip.time" \
    bgzip -@ "$BGZIP_THREADS" -c "$REINSERTED" > "$COMPRESSED"
gzip -t "$COMPRESSED"

# Validate that the Meryl output directory does not already exist
if [[ -e "$MERYL_OUT" ]]; then
    echo "ERROR: Meryl output already exists: $MERYL_OUT" >&2
    echo "Choose another WORKDIR or remove the test output deliberately." >&2
    exit 1
fi

# Count k-mers with Meryl
echo "Counting k-mers with Meryl"
/usr/bin/time -v -o "$WORKDIR/meryl.time" \
    meryl count \
        k="$K" \
        memory="$MERYL_MEMORY" \
        threads="$MERYL_THREADS" \
        output "$MERYL_OUT" \
        "$COMPRESSED"

test -d "$MERYL_OUT"

mkdir -p "$DURABLE_DIR" # for durable outputs

echo "Scratch usage before copying results:"
du -sh "$WORKDIR"
df -h "$WORKDIR"

# Copy the compressed FASTA, Meryl output, and timing reports to the durable directory
cp -a -- "$COMPRESSED" "$MERYL_OUT" "$WORKDIR/bgzip.time" "$WORKDIR/meryl.time" \
    "$DURABLE_DIR/"

echo "Durable outputs and timing reports copied to: $DURABLE_DIR"

echo "Workflow completed successfully"
echo "FASTA records: $HEADER_COUNT"
echo "Total bases: $TOTAL_BP"