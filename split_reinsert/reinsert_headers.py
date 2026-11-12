"""This script reads a headerless sequence from standard input 
and splits it into multiple FASTA records, 
each with a specified chromosome size. 
The output is written to standard output, with each record 
having a header that includes a prefix and a "chromosome" number. """

#!/usr/bin/env python3

import argparse
import sys


""" This function writes a sequence to the output, wrapping it at the specified width.
"""
def write_wrapped(output, sequence, width):
    for start in range(0, len(sequence), width):
        output.write(sequence[start:start + width] + "\n")


""" This function parses command-line arguments, 
reads the input sequence, and splits it into FASTA records. 
Then it writes the records to standard output. 
"""
def main():
    parser = argparse.ArgumentParser(
        description="Split headerless sequence into FASTA records."
    )
    parser.add_argument("--prefix", required=True)
    parser.add_argument("--chromosome-size", type=int, required=True)
    parser.add_argument("--line-width", type=int, default=80)
    args = parser.parse_args()

    if args.chromosome_size <= 0:
        parser.error("--chromosome-size must be positive")
    if args.line_width <= 0:
        parser.error("--line-width must be positive")

    buffer = ""
    record_number = 0

    for raw_line in sys.stdin:
        line = raw_line.strip()

        if not line:
            continue

        if line.startswith(">"):
            raise ValueError(
                "Unexpected FASTA header in input; expected headerless sequence"
            )

        buffer += line

        while len(buffer) >= args.chromosome_size:
            record_number += 1
            chunk = buffer[:args.chromosome_size]
            buffer = buffer[args.chromosome_size:]

            sys.stdout.write(
                f">{args.prefix}_chr{record_number:03d}\n"
            )
            write_wrapped(sys.stdout, chunk, args.line_width)

    if buffer:
        record_number += 1
        sys.stdout.write(f">{args.prefix}_chr{record_number:03d}\n")
        write_wrapped(sys.stdout, buffer, args.line_width)

    if record_number == 0:
        raise ValueError("No sequence found in input")


if __name__ == "__main__":
    main()