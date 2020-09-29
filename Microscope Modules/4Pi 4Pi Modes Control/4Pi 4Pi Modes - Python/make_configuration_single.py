#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import json  # noqa
import sys  # noqa
from glob import glob
from os import path
from pprint import pprint

import matplotlib.pyplot as plt  # noqa
import numpy as np
from h5py import File

from czernike import RZern
from make_configuration_4pi import default_name, get_def_files


def get_noll_indices(args):
    noll_min = np.array(args.min, dtype=np.int)
    noll_max = np.array(args.max, dtype=np.int)
    minclude = np.array(
        [int(s) for s in args.include.split(',') if len(s) > 0], dtype=np.int)
    mexclude = np.array(
        [int(s) for s in args.exclude.split(',') if len(s) > 0], dtype=np.int)
    mrange = np.arange(noll_min, noll_max + 1, dtype=np.int)
    zernike_indices1 = np.setdiff1d(
        np.union1d(np.unique(mrange), np.unique(minclude)),
        np.unique(mexclude))
    zernike_indices = []
    for k in minclude:
        if k in zernike_indices1 and k not in zernike_indices:
            zernike_indices.append(k)
    remaining = np.setdiff1d(zernike_indices1, np.unique(zernike_indices))
    remaining = remaining[np.abs(remaining).argsort()]
    for k in remaining:
        zernike_indices.append(k)
    assert (len(zernike_indices) == zernike_indices1.size)
    zernike_indices = np.array(zernike_indices, dtype=np.int)
    assert (np.unique(zernike_indices).size == zernike_indices.size)

    return zernike_indices


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Make a single objective configuration using Zernikes',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('--zernike-name',
                        dest='zernike_name',
                        action='store_true',
                        help='Include names of Zernike aberrations')
    parser.add_argument('--no-zernike-name',
                        dest='zernike_name',
                        action='store_false')
    parser.set_defaults(zernike_name=1)

    parser.add_argument('--zernike-noll',
                        dest='zernike_noll',
                        action='store_true',
                        help='Include noll index of Zernike aberrations')
    parser.add_argument('--no-zernike-noll',
                        dest='zernike_noll',
                        action='store_false')
    parser.set_defaults(zernike_noll=1)

    parser.add_argument(
        '--zernike-orders',
        dest='zernike_orders',
        action='store_true',
        help='Include radial and azimuthal order of Zernike aberrations')
    parser.add_argument('--no-zernike-orders',
                        dest='zernike_orders',
                        action='store_false')
    parser.set_defaults(zernike_orders=0)

    parser.add_argument('--dm-index',
                        type=int,
                        default=0,
                        help='Select which DM to use')

    parser.add_argument('--flipx', dest='flipx', action='store_true')
    parser.add_argument('--no-flipx', dest='flipx', action='store_false')
    parser.set_defaults(flipx=0)
    parser.add_argument('--flipy', dest='flipy', action='store_true')
    parser.add_argument('--no-flipy', dest='flipy', action='store_false')
    parser.set_defaults(flipy=1)
    parser.add_argument('--rotate',
                        default=0.0,
                        type=float,
                        help='Relative pupil rotation in degrees')
    parser.add_argument('--exclude',
                        type=str,
                        default='1,2,3,4',
                        metavar='INDICES',
                        help='''
Comma separated list of Zernike modes to ignore, e.g.,
"1,2,3,4" to ignore piston, tip, tilt, and defocus.
NB: DO NOT USE SPACES and USE QUOTES!''')
    parser.add_argument('--include',
                        type=str,
                        default='',
                        metavar='INDICES',
                        help='''
Comma separated list of Zernike modes to include. E.g.,
"5,6" to ignore the first order astigmatisms.
NB: DO NOT USE SPACES!''')
    parser.add_argument('--min',
                        type=int,
                        default=5,
                        help='Minimum Zernike Noll index to consider')
    parser.add_argument('--max',
                        type=int,
                        default=22,
                        help='Minimum Zernike Noll index to consider')
    args = parser.parse_args()

    deffiles = get_def_files()
    cfiles = sorted(glob(path.join(deffiles, '*.h5')))
    print('Detected calibration files:')
    for i, c in enumerate(cfiles):
        print(f'dm-index: {i}; file: {c}')
    print(f'dm-index: {args.dm_index}')
    print()
    try:
        selection = int(args.dm_index)
        calibfile = cfiles[int(selection)]
    except Exception:
        while True:
            print('Select the number of the DM you want to use:')
            for i, c in enumerate(cfiles):
                print('', str(i), c)
            try:
                selection = input('Choose number: ')
                calibfile = cfiles[int(selection)]
                print()
                break
            except Exception:
                pass
        selection = int(selection)

    with File(calibfile, 'r') as f:
        wavelength = f['/RegLSCalib/wavelength'][()]
        k = wavelength / (2 * np.pi)
        H = k * f['/RegLSCalib/H'][()]
        C = f['/RegLSCalib/C'][()] / k
        z = f['/RegLSCalib/z0'][()]
        n = int(f['/RegLSCalib/cart/RZern/n'][()])
        serial = f['/RegLSCalib/dm_serial'][()]
        print(f'DM: {serial} file: {calibfile}')
    del serial

    serials = []
    for c in sorted(cfiles):
        with File(c, 'r') as f:
            serials.append(f['/RegLSCalib/dm_serial'][()])

    r = RZern(n)
    assert (r.nk == H.shape[0])
    Nz = r.nk

    if args.rotate is not None:
        R = r.make_rotation(args.rotate)
    else:
        R = 1

    if args.flipx:
        Fx = r.make_xflip()
    else:
        Fx = 1

    if args.flipy:
        Fy = r.make_yflip()
    else:
        Fy = 1

    conf = {}

    # serial numbers
    conf['Serials'] = serials

    # flats excluding ttd
    u = np.zeros(2 * C.shape[0])
    z[:4] = 0
    if selection == 0:
        u[:C.shape[0]] = -np.dot(C, z)
    elif selection == 1:
        u[C.shape[0]:] = -np.dot(C, z)
    else:
        raise NotImplementedError()
    conf['Flats'] = u.tolist()

    # control matrix
    O1 = np.dot(Fy, np.dot(Fx, R))
    C = np.dot(C, O1.T)
    zernike_indices = np.arange(1, Nz + 1)

    zernike_indices = get_noll_indices(args)
    print('Selected Zernike indices are:')
    print(zernike_indices)
    print()

    C = C[:, zernike_indices - 1]
    CC = np.zeros((2 * C.shape[0], C.shape[1]))
    if selection == 0:
        CC[:C.shape[0], :] = C
    elif selection == 1:
        CC[C.shape[0]:, :] = C
    else:
        raise NotImplementedError()

    conf['Matrix'] = CC.tolist()

    # mode names
    ntab = r.ntab
    mtab = r.mtab
    modes = []
    for i in zernike_indices:
        modes.append(default_name(args, i, ntab[abs(i) - 1], mtab[abs(i) - 1]))

    conf['Modes'] = modes
    print('Selected mode names are:')
    pprint(modes)
    print()

    fname = path.join(deffiles, 'config.json')
    with open(fname, 'w') as f:
        json.dump(conf, f, sort_keys=True, indent=4)
    print('Configuration written to:')
    print(path.abspath(fname))
    print()
