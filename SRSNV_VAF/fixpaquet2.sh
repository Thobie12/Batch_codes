#!/bin/bash
#SBATCH --job-name=patch_parquet
#SBATCH --output=logs/patch_parquet_%A_%a.out
#SBATCH --error=logs/patch_parquet_%A_%a.err
#SBATCH --partition=superhimem
#SBATCH --mem=512G
#SBATCH --cpus-per-task=4
#SBATCH --time=24:00:00

module load python3  # load the appropriate python module

set -euo pipefail

# ------------------ INPUTS ------------------
PARQUET_FILE="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/Update/OICRM4CA-07-01-P/OICRM4CA-07-01-P.featuremap_df.parquet"
PATCHED_FILE="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/Update/OICRM4CA-07-01-P/OICRM4CA-07-01-P.patched.parquet"

echo "🔍 Patching parquet file: $PARQUET_FILE"
echo "📦 Output will be: $PATCHED_FILE"

# ------------------ PYTHON PATCH ------------------
python3 << PYTHON_CODE
import pyarrow.parquet as pq
import pyarrow as pa

inp = "$PARQUET_FILE"
out = "$PATCHED_FILE"

dataset = pq.ParquetDataset(inp)
writer = None

for piece in dataset.pieces:
    table = piece.read()
    fixed_cols = [
        col.cast(field.type.value_type) if pa.types.is_dictionary(field.type) else col
        for col, field in zip(table.columns, table.schema)
    ]
    fixed_table = pa.table(fixed_cols, names=table.schema.names)

    if writer is None:
        writer = pq.ParquetWriter(out, fixed_table.schema)
    writer.write_table(fixed_table)

if writer is not None:
    writer.close()

print(f"✅ Patched file written: {out}")
PYTHON_CODE

echo "✅ Done patching."
