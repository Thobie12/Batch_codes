#!/bin/bash
#SBATCH --job-name=patch_parquet
#SBATCH --output=logs/patch_parquet_%A_%a.out
#SBATCH --error=logs/patch_parquet_%A_%a.err
#SBATCH --partition=superhimem
#SBATCH --mem=64G
#SBATCH --cpus-per-task=4
#SBATCH --time=12:00:00

module load python3

set -euo pipefail

PARQUET_FILE="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/Update/OICRM4CA-07-01-P/OICRM4CA-07-01-P.featuremap_df.parquet"
PATCHED_FILE="${PARQUET_FILE%.parquet}.patched.parquet"

echo "🔍 Patching parquet: $PARQUET_FILE"
echo "📦 Output: $PATCHED_FILE"

python3 << 'PYCODE'
import pyarrow as pa
import pyarrow.parquet as pq

inp = "/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/Update/OICRM4CA-07-01-P/OICRM4CA-07-01-P.featuremap_df.parquet"
out = "/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/Update/OICRM4CA-07-01-P/OICRM4CA-07-01-P.featuremap_df.patched.parquet"

dataset = pq.ParquetDataset(inp)  # still works as a wrapper
writer = None

# iterate with dataset.read() in pieces
table = dataset.read()
fixed_cols = [
    col.cast(field.type.value_type) if pa.types.is_dictionary(field.type) else col
    for col, field in zip(table.columns, table.schema)
]
fixed_table = pa.table(fixed_cols, names=table.schema.names)

pq.write_table(fixed_table, out)
print(f"✅ Patched parquet written: {out}")
PYCODE

echo "✅ Done"
