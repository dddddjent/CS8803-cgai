import pyvista as pv
import numpy as np

# Path to the input .vti file
input_vti_path = 'field_0358.vti'
# Path to the output raw binary file
output_raw_path = 'output_file.raw'

# Read the .vti file
fields = pv.read(input_vti_path)
vorticity = fields["vorticity"]
# vorticity = vorticity * 4
vorticity = vorticity.astype(np.float32)
np.save(output_raw_path, vorticity)


print(f"Conversion complete. Raw binary data saved to {output_raw_path}")
