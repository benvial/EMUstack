"""
    test_case_simple_struct.py is a simulation example for EMUstack.

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
Test simulation of a relatively simple structure;
a dilute silicon nanowire array.
Uses .mail file from repository (to avoid meshing discrepancies).
"""


import numpy as np
import testing

from emustack import materials, objects, plotting
from emustack.stack import *

# # Remove results of previous simulations
# plotting.clear_previous()

################ Light parameters #####################

# Set up light objects
wavelengths = np.array([500, 1000])
light_list = [
    objects.Light(wl, max_order_PWs=2, theta=0.0, phi=0.0) for wl in wavelengths
]


################ Scattering matrices (for distinct layers) ##############
""" Calculate scattering matrices for each distinct layer.
Calculated in the order listed below, however this does not influence final
structure which is defined later
"""

# period must be consistent throughout simulation!!!
period = 600

NW_diameter = 120
num_BMs = 40
NW_array = objects.NanoStruct(
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

superstrate = objects.ThinFilm(
    period=period, height_nm="semi_inf", material=materials.Air, loss=False
)

substrate = objects.ThinFilm(
    period=period, height_nm="semi_inf", material=materials.SiO2, loss=False
)


stack_list = []


def simulate_stack(light):

    ################ Evaluate each layer individually ##############
    sim_superstrate = superstrate.calc_modes(light)
    sim_NW_array = NW_array.calc_modes(light, num_BMs=num_BMs)
    sim_substrate = substrate.calc_modes(light)

    ################ Evaluate full solar cell structure ##############
    """ Now when defining full structure order is critical and
    stack list MUST be ordered from bottom to top!
    """
    stack = Stack((sim_substrate, sim_NW_array, sim_superstrate))
    stack.calc_scat(pol="TE")

    return stack


def run_simulation():

    # Run in parallel across wavelengths.
    # This has to be in a setup_module otherwise nosetests will crash :(
    # pool = Pool(2)
    # stack_list = pool.map(simulate_stack, light_list)

    stack_list = [simulate_stack(l) for l in light_list]
    plotting.t_r_a_plots(stack_list, save_txt=True)

    # # SAVE DATA AS REFERENCE
    # # Only run this after changing what is simulated - this
    # # generates a new set of reference answers to check against
    # # in the future
    # testing.save_reference_data("case_1", stack_list)
    return stack_list


case = 1
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
    # rtol = 1e11
    # atol = 1e-1
    # testing.check_results_simu_npz(case, rtol, atol, stack_list)
    plotting.plt.close("all")

if __name__ == "__main__":
    test_stack_list_matches_saved()