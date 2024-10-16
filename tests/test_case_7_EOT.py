"""
test_case_4_EOT.py is a simulation example for EMUstack.

Copyright (C) 2015  Bjorn Sturmberg, Kokou Dossou, Felix Lawrence

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
"""

"""
Test simulation Extraordinary Optical Transmission replicating
Fig 2 of Lie, H - Microscopic theory of the extraordinary optical transmission
doi:10.1038/nature06762
"""

import numpy as np
import testing

from emustack import materials, objects, plotting
from emustack.stack import *

################ Simulation parameters ################


# Number of CPUs to use im simulation
# num_cores = 1


def run_simulation():
	# # Remove results of previous simulations
	# plotting.clear_previous()

	################ Light parameters #####################
	wl_1 = 1.04 * 940
	wl_2 = 1.15 * 940
	no_wl_1 = 1
	# Set up light objects
	wavelengths = np.linspace(wl_1, wl_2, no_wl_1)
	light_list = [
		objects.Light(wl, max_order_PWs=0, theta=0.0, phi=0.0)
		for wl in wavelengths
	]
	light = light_list[0]

	# period must be consistent throughout simulation!!!
	period = 940
	diam1 = 266
	NHs = objects.NanoStruct(
		"2D_array",
		period,
		diam1,
		height_nm=200,
		inclusion_a=materials.Air,
		background=materials.Au,
		loss=True,
		inc_shape="square",
		make_mesh_now=True,
		force_mesh=True,
		lc_bkg=0.05,
		lc2=5.0,
		lc3=3.0,
	)  # lc_bkg = 0.08, lc2= 5.0)

	cover = objects.ThinFilm(
		period=period, height_nm="semi_inf", material=materials.Air, loss=False
	)
	sub = objects.ThinFilm(
		period=period, height_nm="semi_inf", material=materials.Air, loss=False
	)

	num_BMs = 10
	################ Evaluate each layer individually ##############
	sim_NHs = NHs.calc_modes(light, num_BMs=num_BMs)
	sim_cover = cover.calc_modes(light)
	sim_sub = sub.calc_modes(light)

	stack = Stack((sim_sub, sim_NHs, sim_cover))
	stack.calc_scat(pol="TE")
	stack_list = [stack]

	plotting.t_r_a_plots(stack_list, save_txt=True)

	# # # # SAVE DATA AS REFERENCE
	# # # # Only run this after changing what is simulated - this
	# # # # generates a new set of reference answers to check against
	# # # # in the future
	# # Rnet = stack_list[0].R_net[0,0]
	# # print Rnet

	# testing.save_reference_data("case_7", stack_list)
	return stack_list


# def test_stack_list_matches_saved(casefile_name="case_4"):
#     rtol = 1e-4
#     atol = 1e-4
#     ref = np.load("ref/%s.npz" % casefile_name)
#     yield assert_equal, len(stack_list), len(ref["stack_list"])
#     for stack, rstack in zip(stack_list, ref["stack_list"]):
#         yield assert_equal, len(stack.layers), len(rstack["layers"])
#         lbl_s = "wl = %f, " % stack.layers[0].light.wl_nm
#         for i, (lay, rlay) in enumerate(zip(stack.layers, rstack["layers"])):
#             lbl_l = lbl_s + "lay %i, " % i
#             yield assert_ac, lay.R12, rlay["R12"], rtol, atol, lbl_l + "R12"
#             yield assert_ac, lay.T12, rlay["T12"], rtol, atol, lbl_l + "T12"
#             yield assert_ac, lay.R21, rlay["R21"], rtol, atol, lbl_l + "R21"
#             yield assert_ac, lay.T21, rlay["T21"], rtol, atol, lbl_l + "T21"
#             yield assert_ac, lay.k_z, rlay["k_z"], rtol, atol, lbl_l + "k_z"
#             # TODO: yield assert_ac, lay.sol1, rlay['sol1']
#         yield assert_ac, stack.R_net, rstack["R_net"], rtol, atol, lbl_s + "R_net"
#         yield assert_ac, stack.T_net, rstack["T_net"], rtol, atol, lbl_s + "T_net"


case = 7

result_files = (
	"Absorptance_stack0001.txt",
	"Lay_Absorb_0_stack0001.txt",
	"Lay_Trans_0_stack0001.txt",
	"Reflectance_stack0001.txt",
	"Transmittance_stack0001.txt",
)


def test_stack_list_matches_saved():
	stack_list = run_simulation()
	rtol = 1e-1
	atol = 5e-1
	testing.results_match_reference(case, rtol, atol, result_files)
	rtol = 1e-1
	atol = 1e-1
	testing.check_results_simu_npz(case, rtol, atol, stack_list)
	plotting.plt.close("all")


# plotting.clear_previous()

if __name__ == "__main__":
	test_stack_list_matches_saved()
