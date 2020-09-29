# Python scripts to generate the LabVIEW configuration
The VIs contained in this module use a JSON file to load the calibration information for the DMs. You can generate this JSON file with the following Python scripts. These scripts read the calibration information contained in the the DM calibration files (HDF5 files in `4Pi 4Pi Modes - Default Files`). This information is exported to JSON for LabVIEW to load it.

# make_configuration_4pi
Create a configuration using 4Pi modes and both DMs simultanously.

# make_configuration_single
Create a DM configuration using Zernike modes for a single DM.

# run_prompt.bat
Open an Anaconda Prompt in this folder. So you can run the Python scripts.

# test_configuration.py
Test the JSON generated for LabVIEW.
