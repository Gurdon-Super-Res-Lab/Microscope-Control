# Requirements
- For older DMs, you may need to contact BMC to obtain a DM profile file to install in the `Profiles` folder of the BMC software. In addition, you may need to flash the DM driver box EEPROM to write the serial number of the *DM driver box*. Note that the serial number of the *DM driver box* and *DM* are *different*. After that, the BMC software can address each individual DM using its serial number.

# Software installation
- Install Anaconda for Python 3.7 or later 64 bit (https://www.anaconda.com/products/individual; end of page)
- Install latest BMC drivers (e.g. DMSDK 4.1)

# Calibration of the DM with an interferometer
- Tutorial at https://aomicroscopy.org/dm-calib
- Software at https://github.com/jacopoantonello/dmlib
- Software guide at https://github.com/jacopoantonello/dmlib/tree/master/doc
- The calibration generates a *calibration file* like the sample ones contained in `4Pi 4Pi Modes - Default Files`. You need to remove the sample ones and place the ones you generated in that folder.

# Configuration for single objective
- Double click on run_prompt.bat to open a shell
- Type `python make_configuration_single.py` and hit enter to accept the default options and generate the configuration for LabVIEW

This will print all the calibration files stored in `4Pi 4Pi Modes - Default Files`. It will then
generate a configuration file for LabVIEW for the first dm. You can choose which DM to use by specifying the `--dm-index` flag. For example `python make_configuration_single.py --dm-index 0` uses the first DM whereas `python make_configuration_single.py --dm-index 1` the second DM.

You can customise the parameters for the LabVIEW configuration using additional flags. To get a list of the flags, type `python make_configuration_single.py --help` and hit enter.

# Configuration for 4Pi modes
- Double click on run_prompt.bat to open a shell
- Type `python make_configuration_4pi.py` and hit enter to accept the default options and generate the configuration for LabVIEW

# Testing the LabVIEW configuration (no hardware)
- Double click on run_prompt.bat to open a shell
- Type `python test_configuration.py` and hit enter

# Testing the LabVIEW configuration (with hardware)
- Double click on run_prompt.bat to open a shell
- Type `python test_configuration.py --hardware` and hit enter
