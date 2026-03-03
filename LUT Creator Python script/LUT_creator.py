import numpy as np

bits_for_phase = 10
bits_for_amplitude = 10
quarter_sine_lut = True

# Vector de fases
if quarter_sine_lut:
    num_points = 2**(bits_for_phase - 2)  # 1/4 de 2^bits_for_phase
    steps_for_phase = np.linspace(0, np.pi/2, num_points, endpoint=False)
else:    
    steps_for_phase = np.linspace(0, 2*np.pi, 2**bits_for_phase, endpoint=False)

# Sine waveform generation
sin_values = np.sin(steps_for_phase)

# Amplitude range
A_max = 2**(bits_for_amplitude-1) - 1
A_min = -2**(bits_for_amplitude-1)
input_range = (-1, 1)

# Map sine values to amplitude
def map_to_range(x, in_range, out_range):
    in_min, in_max = in_range
    out_min, out_max = out_range
    return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min

# Scaled and round
sin_values_scaled = map_to_range(sin_values, input_range, (A_min, A_max))
sin_values_rounded = np.round(sin_values_scaled).astype(int)

# Ensure it is within range
sin_values_final = np.clip(sin_values_rounded, A_min, A_max)

# Verification
print(f"LUT type: {'1/4 sine wave' if quarter_sine_lut else 'Fully wave'}")
print(f"Bits for phase: {bits_for_phase}")
print(f"Bits for amplitude: {bits_for_amplitude}")
print(f"Number of steps: {len(sin_values_final)}")
print(f"Minimum sine value: {sin_values.min():.6f}")
print(f"Maximum sine value: {sin_values.max():.6f}")
print(f"Minimum mapped value: {sin_values_final.min()}")
print(f"Maximum mapped value: {sin_values_final.max()}")
print(f"5 initial values: {sin_values_final[:5]}")
print(f"5 last values: {sin_values_final[-5:]}\n")

with open("sine_lut_" + str(bits_for_phase) + "x" + str(bits_for_amplitude) + "_pkg.vhd", "w") as f:
    f.write(
'''library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package sine_lut_pkg is\n''')
    
    f.write(f"\tconstant PHASE_WIDTH : integer := {bits_for_phase};\n")
    f.write(f"\tconstant AMPLITUDE_WIDTH : integer := {bits_for_amplitude};\n\n")
    
    f.write("\t"+"type lut_type is array(0 to 2**(PHASE_WIDTH-2)-1) of std_logic_vector(AMPLITUDE_WIDTH-1 downto 0);\n\n")
    
    f.write("\tconstant sine_lut : lut_type := (\n")
    
    for i in range(len(sin_values_final)):
        if i == len(sin_values_final)-1:
            f.write(f"\tstd_logic_vector(to_signed({sin_values_final[i]}, AMPLITUDE_WIDTH))")
        else:
            f.write(f"\tstd_logic_vector(to_signed({sin_values_final[i]}, AMPLITUDE_WIDTH)),\n")
    
    f.write('''
\t);
end package sine_lut_pkg;

''')
