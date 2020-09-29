# Requirements
- For older DMs, you may need to contact BMC to obtain a DM profile file to install in the `Profiles` folder of the BMC software. In addition, you may need to flash the DM driver box EEPROM to write the serial number of the *DM driver box*. Note that the serial number of the *DM driver box* and *DM* are *different*. After that, the BMC software can address each individual DM using its serial number.

# Software installation
- Install Anaconda for Python 3.7 or later 64 bit (https://www.anaconda.com/products/individual; end of page)
- Install latest BMC drivers (e.g. DMSDK 4.0 or later)

# Calibration of the DM with an interferometer
You can perform the calibration of a DM using an interferometer setup and the provided elsewhere.

- Tutorial at https://aomicroscopy.org/dm-calib
- Software at https://github.com/jacopoantonello/dmlib
- Software guide at https://github.com/jacopoantonello/dmlib/tree/master/doc

After performing the calibration of the DM using the resources above you obtain an individual HDF5 for each DM, e.g. `13RW014#041_20190710_214020-2.250mm.h5`. This file contains the DM serial number `13RW014#041` and contains the calibration for a particular aperture size `2.250mm`. You need to generate this file for each of the two DMs and place them in the `4Pi 4Pi Modes - Default Files` folder.

# Use of the calibration from LabVIEW
The scripts in `4Pi 4Pi Modes - Python` can be used to export the calibration from the HDF5 files to LabVIEW.

- use `make_configuration_single.py` to select a single DM and the corresponding Zernike modes
- use `make_configuration_4pi.py` to select both DMs and use 4Pi modes

After running any of the two scripts a JSON file is generated containing the parameters of the calibration. The VIs contained in this module load this configuration up and control the corresponding DM or DMs. You don't need to change any VIs to use a single DM, the other one, or both DMs simultanously. You only need to create a different configuration.

## Configuration for single objective
- Go to `4Pi 4Pi Modes - Python`
- Double click on run_prompt.bat to open a shell
- Type `python make_configuration_single.py` and hit enter to accept the default options and generate the configuration for LabVIEW

This will print all the calibration files stored in `4Pi 4Pi Modes - Default Files`. It will then
generate a configuration file for LabVIEW for the first dm. You can choose which DM to use by specifying the `--dm-index` flag. For example `python make_configuration_single.py --dm-index 0` uses the first DM whereas `python make_configuration_single.py --dm-index 1` the second DM.

You can customise the parameters for the LabVIEW configuration using additional flags. To get a list of the flags, type `python make_configuration_single.py --help` and hit enter.

## Configuration for 4Pi modes
- Go to `4Pi 4Pi Modes - Python`
- Double click on run_prompt.bat to open a shell
- Type `python make_configuration_4pi.py` and hit enter to accept the default options and generate the configuration for LabVIEW

## Testing the JSON file for LabVIEW (no hardware)
- Go to `4Pi 4Pi Modes - Python`
- Double click on run_prompt.bat to open a shell
- Type `python test_configuration.py` and hit enter

## Testing the JSON file for LabVIEW (with hardware)
- Go to `4Pi 4Pi Modes - Python`
- Double click on run_prompt.bat to open a shell
- Type `python test_configuration.py --hardware` and hit enter
