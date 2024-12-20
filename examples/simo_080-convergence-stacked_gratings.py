# simo_080-convergence_stacked_grating.py is a simulation script template for EMUstack.

# Copyright (C) 2015  Bjorn Sturmberg

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
Stacked gratings.
==========================

Replicate Fig 2a from Handmer Opt Lett 2010
"""

from multiprocessing import Pool

import numpy as np

from emustack import materials, objects, plotting
from emustack.stack import *

################ Simulation parameters ################

# Number of CPUs to use in simulation
num_cores = 1

# # Remove results of previous simulations
# plotting.clear_previous()

################ Light parameters #####################
wavelengths = np.linspace(1600, 900, 1)

BMs = [11, 27, 59, 99, 163]#, 227, 299, 395, 507, 635]#, 755, 883, 1059, 1227, 1419]
B = 0

for PWs in np.linspace(1, len(BMs), len(BMs)):
	light_list = [
		objects.Light(wl, max_order_PWs=PWs, theta=28.0, phi=0.0)
		for wl in wavelengths
	]

	################ Grating parameters #####################
	period = 760

	superstrate = objects.ThinFilm(
		period,
		height_nm="semi_inf",
		material=materials.Air,
		world_1d=True,
		loss=False,
	)

	substrate = objects.ThinFilm(
		period,
		height_nm="semi_inf",
		material=materials.Air,
		world_1d=True,
		loss=False,
	)
	lc_bkg = 0.01

	grating_1 = objects.NanoStruct(
		"1D_array",
		period,
		small_space=period / 2,
		diameter1=int(round(0.25 * period)),
		diameter2=int(round(0.25 * period)),
		height_nm=150,
		inclusion_a=materials.Material(3.61 + 0.0j),
		inclusion_b=materials.Material(3.61 + 0.0j),
		background=materials.Material(1.46 + 0.0j),
		loss=True,
		make_mesh_now=True,
		force_mesh=True,
		lc_bkg=lc_bkg,
		lc2=3.0*1,
	)

	grating_2 = objects.NanoStruct(
		"1D_array",
		period,
		int(round(0.75 * period)),
		height_nm=2900,
		background=materials.Material(1.46 + 0.0j),
		inclusion_a=materials.Material(3.61 + 0.0j),
		loss=True,
		make_mesh_now=True,
		force_mesh=True,
		lc_bkg=lc_bkg,
		lc2=3.0*1,
	)

	num_BMs = BMs[B] + 30
	print(num_BMs)
	B += 1

	def simulate_stack(light):
		################ Evaluate each layer individually ##############
		sim_superstrate = superstrate.calc_modes(light)
		sim_substrate = substrate.calc_modes(light)
		sim_grating_1 = grating_1.calc_modes(light, num_BMs=num_BMs)
		sim_grating_2 = grating_2.calc_modes(light, num_BMs=num_BMs)

		###################### Evaluate structure ######################
		""" Now define full structure. Here order is critical and
            stack list MUST be ordered from bottom to top!
        """

		stack = Stack(
			(sim_substrate, sim_grating_1, sim_grating_2, sim_superstrate)
		)
		# stack = Stack((sim_substrate, sim_grating_2, sim_superstrate))
		stack.calc_scat(pol="TE")
		return stack

	# Run in parallel across wavelengths.
	pool = Pool(num_cores)
	stacks_list = pool.map(simulate_stack, light_list)
	# stacks_list = [simulate_stack([light]) for light in light_list]
	# # Save full simo data to .npz file for safe keeping!
	# np.savez("Simo_results", stacks_list=stacks_list)

	additional_name = str(int(PWs))
	plotting.t_r_a_plots(stacks_list, add_name=additional_name)
