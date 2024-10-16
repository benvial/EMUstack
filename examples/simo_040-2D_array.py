# simo_040-2D_array.py is a simulation example for EMUstack.

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
Nanowire array.
==============

Simulating a nanowire array with period 600 nm and NW diameter 120 nm.
"""

from multiprocessing import Pool

import numpy as np

from emustack import materials, objects, plotting
from emustack.stack import *

################ Simulation parameters ################

# Number of CPUs to use in simulation
num_cores = 1

# Remove results of previous simulations
plotting.clear_previous()

################ Light parameters #####################
wl_1 = 310
wl_2 = 1127
no_wl_1 = 3
# Set up light objects
wavelengths = np.linspace(wl_1, wl_2, no_wl_1)
light_list = [
	objects.Light(wl, max_order_PWs=2, theta=0.0, phi=0.0)
	for wl in wavelengths
]

# Period must be consistent throughout simulation!!!
period = 600

# In this example we set the number of Bloch modes to use in the simulation
# Be default it is set to be slightly greater than the number of PWs.
num_BMs = 200

superstrate = objects.ThinFilm(
	period, height_nm="semi_inf", material=materials.Air, loss=False
)

substrate = objects.ThinFilm(
	period, height_nm="semi_inf", material=materials.SiO2, loss=False
)

NW_diameter = 120
NW_array = objects.NanoStruct(
	"2D_array",
	period,
	NW_diameter,
	height_nm=2330,
	inclusion_a=materials.Si_c,
	background=materials.Air,
	loss=True,
	make_mesh_now=True,
	force_mesh=True,
	lc_bkg=0.1,
	lc2=2.0,
)
# Here we get EMUstack to make the FEM mesh automagically using our input parameters.
# the lc_bkg parameter sets the baseline distance between points on the FEM mesh,
# lc_bkg/lc2 is the distance between mesh points that lie on the inclusion boundary.
# There are higher lc parameters which are used when including multiple inclusions.

# Alternatively we can specify a pre-made mesh as follows.
NW_array2 = objects.NanoStruct(
	"2D_array",
	period,
	NW_diameter,
	height_nm=2330,
	inclusion_a=materials.Si_c,
	background=materials.Air,
	loss=True,
	make_mesh_now=False,
	mesh_file="4testing-600_120.mail",
)


def simulate_stack(light):
	################ Evaluate each layer individually ##############
	sim_superstrate = superstrate.calc_modes(light)
	sim_substrate = substrate.calc_modes(light)
	sim_NWs = NW_array.calc_modes(light, num_BMs=num_BMs)

	###################### Evaluate structure ######################
	""" Now define full structure. Here order is critical and
        stack list MUST be ordered from bottom to top!
    """

	stack = Stack((sim_substrate, sim_NWs, sim_superstrate))
	stack.calc_scat(pol="TE")

	return stack


# Run in parallel across wavelengths.
pool = Pool(num_cores)
stacks_list = pool.map(simulate_stack, light_list)
# Save full simo data to .npz file for safe keeping!
np.savez("Simo_results", stacks_list=stacks_list)


######################## Plotting ########################

# We here wish to know the photovoltaic performance of the structure,
# where all light absorbed in the NW layer is considered to produce exactly
# one electron-hole pair.
# To do this we specify which layer of the stack is the PV active layer
# (default active_layer_nu=1), and indicate that we want to calculate
# the ideal short circuit current (J_sc) of the cell.
# We could also calculate the 'ultimate efficiency' by setting ult_eta=True.
plotting.t_r_a_plots(stacks_list, active_layer_nu=1, J_sc=True)

# We also plot the dispersion relation for each layer.
plotting.omega_plot(stacks_list, wavelengths)
