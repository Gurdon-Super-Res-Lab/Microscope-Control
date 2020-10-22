# HDF5 calibration files folder

You can drop in this folder multiple *calibration files* generated for different DMs and different aperture sizes.

Use the following resources to generate such files:

- Tutorial at https://aomicroscopy.org/dm-calib
- Software at https://github.com/jacopoantonello/dmlib
- Software guide at https://github.com/jacopoantonello/dmlib/tree/master/doc

These files cannot be loaded directly in LabVIEW. But you can extract the parameters needed by LabVIEW by running the scripts in `4Pi 4Pi Modes - Python`. The files included in this folder are for example only and you should replace them with your own calibrations.
