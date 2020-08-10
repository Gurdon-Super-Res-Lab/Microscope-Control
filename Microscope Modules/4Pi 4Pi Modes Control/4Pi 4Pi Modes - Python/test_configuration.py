#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import json  # noqa
import sys
from os import path

import matplotlib.pyplot as plt  # noqa
import numpy as np
from matplotlib.backends.backend_qt5agg import FigureCanvas
from matplotlib.figure import Figure
from numpy.linalg import norm
from PyQt5.QtCore import Qt
from PyQt5.QtWidgets import (QApplication, QDoubleSpinBox, QFrame, QGridLayout,
                             QLabel, QMainWindow, QPushButton, QScrollArea,
                             QSlider, QSplitter, QWidget)

from dmplot import DMPlot
from make_configuration_4pi import get_def_files

MAX_NM = 5500


class RelSlider:
    def __init__(self, val, cb):
        self.old_val = None
        self.fto100mul = 100
        self.cb = cb

        self.sba = QDoubleSpinBox()
        self.sba.setMinimum(-MAX_NM)
        self.sba.setMaximum(MAX_NM)
        self.sba.setDecimals(6)
        self.sba.setToolTip('Effective value [nm]')
        self.sba.setValue(val)
        self.sba_color(val)
        self.sba.setSingleStep(1.25e-3)

        self.qsr = QSlider(Qt.Horizontal)
        self.qsr.setMinimum(-100)
        self.qsr.setMaximum(100)
        self.qsr.setValue(0)
        self.qsr.setToolTip('Drag to apply relative delta [nm]')

        self.sbm = QDoubleSpinBox()
        self.sbm.setMinimum(MAX_NM / 2)
        self.sbm.setMaximum(MAX_NM)
        self.sbm.setSingleStep(1.25e-3)
        self.sbm.setToolTip('Maximum relative delta [nm]')
        self.sbm.setDecimals(2)
        self.sbm.setValue(4.0)

        def sba_cb():
            def f():
                self.block()
                val = self.sba.value()
                self.sba_color(val)
                self.cb(val)
                self.unblock()

            return f

        def qs1_cb():
            def f(t):
                self.block()

                if self.old_val is None:
                    self.qsr.setValue(0)
                    self.unblock()
                    return

                val = self.old_val + self.qsr.value() / 100 * self.sbm.value()
                self.sba.setValue(val)
                self.sba_color(val)
                self.cb(val)

                self.unblock()

            return f

        def qs1_end():
            def f():
                self.block()
                self.qsr.setValue(0)
                self.old_val = None
                self.unblock()

            return f

        def qs1_start():
            def f():
                self.block()
                self.old_val = self.get_value()
                self.unblock()

            return f

        self.sba_cb = sba_cb()
        self.qs1_cb = qs1_cb()
        self.qs1_start = qs1_start()
        self.qs1_end = qs1_end()

        self.sba.valueChanged.connect(self.sba_cb)
        self.qsr.valueChanged.connect(self.qs1_cb)
        self.qsr.sliderPressed.connect(self.qs1_start)
        self.qsr.sliderReleased.connect(self.qs1_end)

    def sba_color(self, val):
        if abs(val) > 1e-4:
            self.sba.setStyleSheet("font-weight: bold;")
        else:
            self.sba.setStyleSheet("font-weight: normal;")
        # self.sba.update()

    def block(self):
        self.sba.blockSignals(True)
        self.qsr.blockSignals(True)
        self.sbm.blockSignals(True)

    def unblock(self):
        self.sba.blockSignals(False)
        self.qsr.blockSignals(False)
        self.sbm.blockSignals(False)

    def enable(self):
        self.sba.setEnabled(True)
        self.qsr.setEnabled(True)
        self.sbm.setEnabled(True)

    def disable(self):
        self.sba.setEnabled(False)
        self.qsr.setEnabled(False)
        self.sbm.setEnabled(False)

    def fto100(self, f):
        return int((f + self.m2) / (2 * self.m2) * self.fto100mul)

    def get_value(self):
        return self.sba.value()

    def set_value(self, v):
        self.sba_color(v)
        return self.sba.setValue(v)

    def add_to_layout(self, l1, ind1, ind2):
        l1.addWidget(self.sba, ind1, ind2)
        l1.addWidget(self.qsr, ind1, ind2 + 1)
        l1.addWidget(self.sbm, ind1, ind2 + 2)

    def remove_from_layout(self, l1):
        l1.removeWidget(self.sba)
        l1.removeWidget(self.qsr)
        l1.removeWidget(self.sbm)

        self.sba.setParent(None)
        self.qsr.setParent(None)
        self.sbm.setParent(None)

        self.sba.valueChanged.disconnect(self.sba_cb)
        self.qsr.valueChanged.disconnect(self.qs1_cb)
        self.qsr.sliderPressed.disconnect(self.qs1_start)
        self.qsr.sliderReleased.disconnect(self.qs1_end)

        self.sba_cb = None
        self.qs1_cb = None
        self.qs1_start = None
        self.qs1_end = None

        self.sb = None
        self.qsr = None


class SquareRoot:

    name = 'v = 2.0*np.sqrt((u + 1.0)/2.0) - 1.0'

    def __call__(self, u):
        assert (np.all(np.isfinite(u)))

        if norm(u, np.inf) > 1.:
            u[u > 1.] = 1.
            u[u < -1.] = -1.
        assert (norm(u, np.inf) <= 1.)

        v = 2 * np.sqrt((u + 1.0) / 2.0) - 1.0
        assert (np.all(np.isfinite(v)))
        assert (norm(v, np.inf) <= 1.)
        del u

        return v

    def __str__(self):
        return self.name


class DMWindow(QMainWindow):
    def __init__(self, args, app, C, modes, serials):
        super().__init__()
        self.args = args
        self.C = C
        self.modes = modes
        self.serials = serials
        self.dmplot0 = DMPlot()
        if C.shape[0] == 140:
            self.dmplot1 = None
        else:
            self.dmplot1 = DMPlot()

        hwdms = []
        if args.hardware:
            try:
                from bmc import BMC
            except Exception:
                try:
                    from devwraps.bmc import BMC
                except Exception:
                    raise ValueError('Cannot open DMs')

            for s in serials:
                d = BMC()
                d.open(s)
                d.set_transform(SquareRoot())
                hwdms.append(d)

        self.u = np.zeros(C.shape[0])
        self.z = np.zeros(C.shape[1])

        fig0 = FigureCanvas(Figure(figsize=(2, 2)))
        ax0 = fig0.figure.subplots(1, 1)
        ima0 = self.dmplot0.draw(ax0, self.u[:140])
        ax0.axis('off')

        if self.dmplot1:
            fig1 = FigureCanvas(Figure(figsize=(2, 2)))
            ax1 = fig1.figure.subplots(1, 1)
            ima1 = self.dmplot1.draw(ax1, self.u[140:])
            ax1.axis('off')

        def update():
            self.u = np.dot(self.C, self.z)
            ima0.set_data(self.dmplot0.compute_pattern(self.u[:140]))
            ax0.figure.canvas.draw()
            if self.dmplot1:
                ima1.set_data(self.dmplot1.compute_pattern(self.u[140:]))
                ax1.figure.canvas.draw()
            count = 0
            for h in hwdms:
                h.write(self.u[count:(count + 140)])
                count += 140

        def make_callback(i):
            def f(r):
                self.z[i] = r
                update()

            return f

        scroll = QScrollArea()
        scroll.setWidget(QWidget())
        scroll.setWidgetResizable(True)
        lay = QGridLayout(scroll.widget())
        self.sliders = []
        for i in range(len(modes)):
            lab = QLabel(modes[i])
            slider = RelSlider(0., make_callback(i))
            lay.addWidget(lab, i, 0)
            slider.add_to_layout(lay, i, 1)
            self.sliders.append(slider)

        breset = QPushButton('reset')

        def reset_fun():
            self.z *= 0.
            for s in self.sliders:
                s.block()
                s.set_value(0.)
                s.unblock()
            update()

        breset.clicked.connect(reset_fun)

        main = QSplitter(Qt.Vertical)
        top = QFrame()
        lay = QGridLayout()
        top.setLayout(lay)
        lay.addWidget(fig0, 0, 0)
        if self.dmplot1:
            lay.addWidget(fig1, 0, 1)
        lay.addWidget(breset, 1, 0)
        main.addWidget(top)
        main.addWidget(scroll)
        self.setCentralWidget(main)


if __name__ == '__main__':
    app = QApplication(sys.argv)

    args = app.arguments()
    parser = argparse.ArgumentParser(
        description='', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--hardware',
                        action='store_true',
                        help='Actually drive the DM hardware')
    args = parser.parse_args(args[1:])

    fname = path.join(get_def_files(), 'config.json')
    with open(fname, 'r') as f:
        conf = json.load(f)

    C = np.array(conf['Matrix'])
    modes = conf['Modes']
    serials = conf['Serials']

    zwindow = DMWindow(args, app, C, modes, serials)
    zwindow.show()

    sys.exit(app.exec_())
