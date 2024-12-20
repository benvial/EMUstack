"""
test_case_5_EOT_5_degrees.py is a simulation example for EMUstack.

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

# # Remove results of previous simulations
# plotting.clear_previous()


def run_simulation():
	################ Light parameters #####################
	wl_1 = 1.11 * 940
	wl_2 = 1.15 * 940
	no_wl_1 = 1
	# Set up light objects
	wavelengths = np.linspace(wl_1, wl_2, no_wl_1)
	light_list = [
		objects.Light(wl, max_order_PWs=1, theta=5.0, phi=0.0)
		for wl in wavelengths
	]
	light = light_list[0]

	# period must be consistent throughout simulation!!!
	period = 940
	diameter = 266
	NHs = objects.NanoStruct(
		"2D_array",
		period,
		diameter,
		height_nm=200,
		inclusion_a=materials.Air,
		background=materials.Au,
		loss=True,
		inc_shape="square",
		make_mesh_now=False,
		mesh_file="4testing-940_266_sq.mail",
	)

	superstrate = objects.ThinFilm(
		period=period, height_nm="semi_inf", material=materials.Air, loss=False
	)

	substrate = objects.ThinFilm(
		period=period, height_nm="semi_inf", material=materials.Air, loss=False
	)

	num_BM = 11
	################ Evaluate each layer individually ##############
	sim_NHs = NHs.calc_modes(light, num_BMs=num_BM)
	sim_superstrate = superstrate.calc_modes(light)
	sim_substrate = substrate.calc_modes(light)

	stack = Stack((sim_substrate, sim_NHs, sim_superstrate))
	stack.calc_scat(pol="TM")
	stack_list = [stack]
	plotting.t_r_a_plots(stack_list, save_txt=True)

	# # # # SAVE DATA AS REFERENCE
	# # # # Only run this after changing what is simulated - this
	# # # # generates a new set of reference answers to check against
	# # # # in the future
	# # num_pw_per_pol = stack_list[0].layers[0].structure.num_pw_per_pol
	# # Rnet = stack_list[0].R_net[num_pw_per_pol,num_pw_per_pol]
	# # print Rnet
	# testing.save_reference_data("case_5", stack_list)
	return stack_list


# def test_stack_list_matches_saved(casefile_name="case_5"):
#     stack_list = simulate_stack()
#     rtol = 1e-4
#     atol = 1e-4
#     rtol_mats = 1e-4
#     atol_mats = 1e-1
#     ref = np.load("ref/%s.npz" % casefile_name)
#     ref = np.load("ref/%s.npz" % casefile_name, allow_pickle=True, encoding="latin1")
#     assert_equal(len(stack_list), len(ref["stack_list"]))
#     for stack, rstack in zip(stack_list, ref["stack_list"]):
#         assert_equal(len(stack.layers), len(rstack["layers"]))
#         lbl_s = "wl = %f, " % stack.layers[0].light.wl_nm
#         for i, (lay, rlay) in enumerate(zip(stack.layers, rstack["layers"])):
#             lbl_l = lbl_s + "lay %i, " % i
#             assert_ac(lay.R12, rlay["R12"], rtol_mats, atol_mats, lbl_l + "R12")
#             assert_ac(lay.T12, rlay["T12"], rtol_mats, atol_mats, lbl_l + "T12")
#             assert_ac(lay.R21, rlay["R21"], rtol_mats, atol_mats, lbl_l + "R21")
#             assert_ac(lay.T21, rlay["T21"], rtol_mats, atol_mats, lbl_l + "T21")
#             assert_ac(lay.k_z, rlay["k_z"], rtol_mats, atol_mats, lbl_l + "k_z")
#             # TODO: yield assert_ac, lay.sol1, rlay['sol1']
#         assert_ac(stack.R_net, rstack["R_net"], rtol, atol, lbl_s + "R_net")
#         assert_ac(stack.T_net, rstack["T_net"], rtol, atol, lbl_s + "T_net")


# plotting.clear_previous()


case = 5

result_files = (
	"Absorptance_stack0001.txt",
	"Lay_Absorb_0_stack0001.txt",
	"Lay_Trans_0_stack0001.txt",
	"Reflectance_stack0001.txt",
	"Transmittance_stack0001.txt",
)


def test_stack_list_matches_saved():
	stack_list = run_simulation()
	rtol = 1e-0
	atol = 1e-4
	testing.results_match_reference(case, rtol, atol, result_files)
	rtol = 1e-3
	atol = 1e-3
	testing.check_results_simu_npz(case, rtol, atol, stack_list)
	plotting.plt.close("all")


if __name__ == "__main__":
	test_stack_list_matches_saved()
