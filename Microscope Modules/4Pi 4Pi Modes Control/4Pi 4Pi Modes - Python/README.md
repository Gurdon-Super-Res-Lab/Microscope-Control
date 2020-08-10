# Requirements
- For older DMs, you may need to contact BMC to obtain a DM profile file to install in the `Profiles` folder of the BMC software. In addition, you may need to flash the DM driver box EEPROM to write the serial number of the *DM driver box*. Note that the serial number of the *DM driver box* and *DM* are *different*. After that, the BMC software can address each individual DM using its serial number.

# Software installation
- Install Anaconda for Python 3 64 bit (https://www.anaconda.com/products/individual; end of page)
- Install latest BMC drivers (e.g. DMSDK 4.1)

# Calibration of the DM with an interferometer
- Tutorial at https://aomicroscopy.org/dm-calib
- Software at https://github.com/jacopoantonello/dmlib
- Software guide at https://github.com/jacopoantonello/dmlib/tree/master/doc
- The calibration generates a *calibration file* like the sample ones contained in `4Pi 4Pi Modes - Default Files`. You need to remove the sample ones and place the ones you generated in that folder.

# Configuration
- Double click on run_prompt.bat to open a shell
- Type `python make_configuration_4pi.py --help` and hit enter
  - A list of available options will be printed on the console
  - Choose your preferred options
- Type `python make_configuration_4pi.py ` followed by your preferred options without `--help` and hit enter
- Test the modes by running `python test_configuration.py`
