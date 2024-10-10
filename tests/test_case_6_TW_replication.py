"""
    test_case_6_TW.py is a simulation example for EMUstack.

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
Test simulation of a relatively difficult structure;
a multilayered stack including a dielectric grating and silver mirror.
"""

import numpy as np
import testing

from emustack import materials, objects, plotting
from emustack.stack import *

# The following should be in the function "setup_module()",
# but unfortunately simulate_stack is defined in a lazy-but-easy
# way: the structures are inherited rather than passed in.

################ Simulation parameters ################

# Number of CPUs to use im simulation
num_cores = 1
# # Alternatively specify the number of CPUs to leave free on machine
# leave_cpus = 4
# num_cores = mp.cpu_count() - leave_cpus

# # Remove results of previous simulations
# plotting.clear_previous()

################ Light parameters #####################
# wl_1     = 900
# wl_2     = 1050
# no_wl_1  = 2
# # Set up light objects
# wavelengths = np.linspace(wl_1, wl_2, no_wl_1)
# light_list  = [objects.Light(wl, max_order_PWs = 3) for wl in wavelengths]
# # Single wavelength run
wl_super = 1000
wavelengths = np.array([wl_super])
light_list = [
    objects.Light(wl, max_order_PWs=2, theta=0.0, phi=0.0) for wl in wavelengths
]


# period must be consistent throughout simulation!!!
period = 120

cover = objects.ThinFilm(
    period=period,
    height_nm="semi_inf",
    material=materials.Material(3.5 + 0.0j),
    loss=True,
    world_1d=True,
)

homo_film = objects.ThinFilm(
    period=period,
    height_nm=5,
    material=materials.Material(3.6 + 0.27j),
    loss=True,
    world_1d=True,
)

bottom = objects.ThinFilm(
    period=period,
    height_nm="semi_inf",
    material=materials.Air,
    loss=False,
    world_1d=True,
)

grating_diameter = 100
grating_1 = objects.NanoStruct(
    "1D_array",
    period,
    grating_diameter,
    height_nm=25,
    inclusion_a=materials.Ag,
    background=materials.Material(1.5 + 0.0j),
    loss=True,
    make_mesh_now=True,
    force_mesh=True,
    lc_bkg=0.05,
    lc2=4.0,
)

mirror = objects.ThinFilm(
    period=period,
    height_nm=100,
    material=materials.Ag,
    loss=True,
    world_1d=True,
)


stack_list = []


def simulate_stack(light):

    ################ Evaluate each layer individually ##############
    sim_cover = cover.calc_modes(light)
    sim_homo_film = homo_film.calc_modes(light)
    sim_bot = bottom.calc_modes(light)
    sim_grat1 = grating_1.calc_modes(light)
    sim_mirror = mirror.calc_modes(light)

    ################ Evaluate full solar cell structure ##############
    """ Now when defining full structure order is critical and
    solar_cell list MUST be ordered from bottom to top!
    """
    stack = Stack((sim_bot, sim_mirror, sim_grat1, sim_homo_film, sim_cover))
    stack.calc_scat(pol="TE")

    return stack


def run_simulation():

    # Run in parallel across wavelengths.
    stack = simulate_stack(light_list[0])
    stack_list = [stack]

    active_layer_nu = 3  # Specify which layer is the active one (where absorption generates charge carriers).

    plotting.t_r_a_plots(stack_list, active_layer_nu=active_layer_nu, save_txt=True)

    # # SAVE DATA AS REFERENCE
    # # Only run this after changing what is simulated - this
    # # generates a new set of reference answers to check against
    # # in the future
    # testing.save_reference_data("case_6", stack_list)

    
    return stack_list


case = 6

result_files = (
    "Absorptance_stack0001.txt",
    "Lay_Absorb_0_stack0001.txt",
    "Lay_Trans_0_stack0001.txt",
    "Lay_Absorb_1_stack0001.txt",
    "Lay_Trans_1_stack0001.txt",
    "Lay_Absorb_2_stack0001.txt",
    "Lay_Trans_2_stack0001.txt",
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