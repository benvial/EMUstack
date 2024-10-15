# simo_091-.py is a simulation script template for EMUstack.

# Copyright (C) 2015  Bjorn Sturmberg, J. Scott Brownless

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


"""
Dispersion relations.
====================

Finding the dispersion relations of the modes of drawn metamaterial
slab. This simulation replicates The darkest curve of Fig. 4 of
http://dx.doi.org/10.1103/PhysRevB.91.155427
(using the parameters from the original Lemoult, Fink metalens).
mode_finder function implemented by J. Scott Brownless.
"""

from multiprocessing import Pool

import matplotlib.pyplot as plt
import numpy as np
from scipy import optimize

from emustack import materials, objects, plotting
from emustack.stack import *

################ Simulation parameters ################
# Number of CPUs to use in simulation
num_cores = 1

################ Light parameters #####################
c_speed = 299792458
wl_0 = 0.8e9
f_0 = c_speed / wl_0
k_0 = 2 * np.pi / wl_0
omega_0 = 2 * np.pi * f_0
min_freq = 0.712 * f_0
max_freq = 1.0 * f_0
n_freqs = 2
min_kx = 0.6 * k_0
max_kx = 30 * k_0
n_kxs = 40
freq_list = np.linspace(max_freq, min_freq, n_freqs)
wl_list = c_speed / freq_list
kx_list = np.linspace(min_kx, max_kx, n_kxs)
light_list = []
for kx in kx_list:
	for wl in wl_list:
		light_list.append((wl, kx))

# period must be consistent throughout simulation!!!
period = 0.012e9
n = 1
L = 0.4e9

strate = objects.ThinFilm(
	period, height_nm="semi_inf", material=materials.Air, loss=False
)

NW_rads = 0.0015e9
dummy_diameter = 1
NW_diameter = NW_rads * 2
NW_array = objects.NanoStruct(
	"2D_array",
	period,
	NW_diameter,
	height_nm=wl_0 / (2 * n),
	inclusion_a=materials.Material(0.0 + 1e6j),
	background=materials.Material(n),
	loss=True,
	hyperbolic=True,
	make_mesh_now=True,
	force_mesh=True,
	lc_bkg=0.2,
	lc2=4.0,
)


def simulate_stack(lyte):
	num_BMs = 11
	wl = lyte[0]
	kx = lyte[1]
	light = objects.Light(wl, max_order_PWs=1, k_parallel=[kx, 0.000000000001])
	################ Evaluate each layer individually ##############
	sim_NWs = NW_array.calc_modes(light, num_BMs=num_BMs)
	sim_strate = strate.calc_modes(light)
	stack = Stack((sim_strate, sim_NWs, sim_strate))
	stack.calc_scat(pol="TE")
	###### Find the Fabry Perot modes ######
	num_BMs = sim_NWs.num_BMs
	I_mat = np.matrix(np.eye(num_BMs), dtype="D")
	height = stack.heights_nm()[0]
	lay_interest = 1
	P = stack.layers[lay_interest].prop_fwd(height / period)
	R21 = stack.layers[lay_interest].R21
	det = np.linalg.det(I_mat - R21 * P * R21 * P)
	detskew = np.exp(1j) * det
	return detskew


def mode_finder(disp_input):
	(det_mat_slice, wl_list, kx) = disp_input
	dispcurve = []
	xtol = 1e-4 * wl_0
	for j in range(len(wl_list) - 1):
		# Check determinant crosses zero, both real and imaginary
		if np.real(det_mat_slice[j]) * np.real(det_mat_slice[j + 1]) < 0:
			if np.imag(det_mat_slice[j]) * np.imag(det_mat_slice[j + 1]) < 0:
				diffreq = np.abs(det_mat_slice[j - 1] - det_mat_slice[j])
		
				# Check we are not just at a discontinuity
				if (
					np.abs(det_mat_slice[j + 1] - det_mat_slice[j])
					< 3 * diffreq
				):
					try:
						# Optimise the wl
						finwl = optimize.brentq(
							lambda wl: np.real(
								np.exp(1j) * simulate_stack([wl, kx])
							),
							wl_list[j],
							wl_list[j + 1],
							rtol=1e-3,
							xtol=xtol,
						)
						findet = simulate_stack([finwl, kx])
						print("#################################")
						print("found root = ", findet)
						print("#################################")
						# check the final determinant is below some tolerance
						if np.abs(findet) < 1.0e-3:
							finfreq = 2 * np.pi * c_speed * 1e9 / finwl
							dispcurve.append((kx * 1e9, finfreq))
					except AttributeError:
						print(det_mat_slice[j], det_mat_slice[j + 1])
	return dispcurve


# Run in parallel across wavelengths.
pool = Pool(num_cores)
stacks_list = pool.map(simulate_stack, light_list)

stacks_mat = np.array(stacks_list).reshape(len(kx_list), len(wl_list))

disp_input = []
for i in range(len(kx_list)):
	k = kx_list[i]
	stacks_mat_slice = stacks_mat[i, :]
	disp_input.append((stacks_mat_slice, wl_list, k))

dispy = pool.map(mode_finder, disp_input)
displist = []
for dixp in dispy:
	displist += dixp

displist = np.array(displist)
k_norm = 1e-9 * displist[:,0] / k_0
omega_norm = 1e-9 * displist[:,1] / omega_0

plt.figure()
plt.plot(k_norm,omega_norm)
plt.xlabel(r"$k/k_0$")
plt.ylabel(r"$\omega/\omega_0$")


