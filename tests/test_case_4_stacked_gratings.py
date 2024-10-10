"""
    test_case_4_stacked_gratings.py is a simulation example for EMUstack.

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
Test simulation of stacked 1D gratings.
"""


import numpy as np
import testing

from emustack import materials, objects, plotting
from emustack.stack import *


def run_simulation():
    # # Remove results of previous simulations
    # plotting.clear_previous()

    ################ Light parameters #####################
    wavelengths = np.linspace(800, 1600, 1)
    light_list = [
        objects.Light(wl, max_order_PWs=6, theta=0.0, phi=0.0) for wl in wavelengths
    ]
    light = light_list[0]

    period = 760

    superstrate = objects.ThinFilm(
        period, height_nm="semi_inf", world_1d=True, material=materials.Air, loss=False
    )

    substrate = objects.ThinFilm(
        period, height_nm="semi_inf", world_1d=True, material=materials.Air, loss=False
    )
    

    grating_1 = objects.NanoStruct(
        "1D_array",
        period,
        diameter1=int(round(0.25 * period)),
        diameter2=int(round(0.25 * period)),
        height_nm=150,
        inclusion_a=materials.Material(1.46 + 0.0j),
        inclusion_b=materials.Material(1.46 + 0.0j),
        background=materials.Material(3.61 + 0.0j),
        loss=True,
        lc_bkg=0.005,
    )

    grating_2 = objects.NanoStruct(
        "1D_array",
        period,
        int(round(0.25 * period)),
        height_nm=900,
        background=materials.Material(3.61 + 0.0j),
        inclusion_a=materials.Material(1.46 + 0.0j),
        loss=True,
        lc_bkg=0.005,
    )

    

    ################ Evaluate each layer individually ##############
    sim_superstrate = superstrate.calc_modes(light)
    sim_substrate = substrate.calc_modes(light)
    sim_grating_1 = grating_1.calc_modes(light)
    sim_grating_2 = grating_2.calc_modes(light)

    ################ Evaluate full solar cell structure ##############
    """ Now when defining full structure order is critical and
    stack list MUST be ordered from bottom to top!
    """

    stack = Stack((sim_substrate, sim_grating_1, sim_grating_2, sim_superstrate))
    stack.calc_scat(pol="TE")
    stack_list = [stack]


    

    plotting.t_r_a_plots(stack_list, save_txt=True)

    # # SAVE DATA AS REFERENCE
    # # Only run this after changing what is simulated - this
    # # generates a new set of reference answers to check against
    # # in the future
    # testing.save_reference_data("case_4", stack_list)
    return stack_list


case = 4
result_files = (
    "Absorptance_stack0001.txt",
    "Lay_Absorb_0_stack0001.txt",
    "Lay_Absorb_1_stack0001.txt",
    "Lay_Trans_0_stack0001.txt",
    "Lay_Trans_1_stack0001.txt",
    "Reflectance_stack0001.txt",
    "Transmittance_stack0001.txt",
)


def test_stack_list_matches_saved():
    stack_list = run_simulation()
    rtol = 1e-1
    atol = 5e-1
    testing.results_match_reference(case, rtol, atol, result_files)
    rtol = 1e15
    atol = 1e-1
    testing.check_results_simu_npz(case, rtol, atol, stack_list)
    plotting.plt.close("all")


# plotting.clear_previous()



if __name__ == "__main__":
    test_stack_list_matches_saved()