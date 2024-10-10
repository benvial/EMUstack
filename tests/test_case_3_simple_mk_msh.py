"""
    test_case_3_simple_mk_msh.py is a simulation example for EMUstack.

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
a dilute InP nanowire array.
Tests the creation of new .mail file via Gmsh.
"""

import numpy as np
import testing

from emustack import materials, objects, plotting
from emustack.stack import *


def run_simulation():
    ################ Light parameters #####################

    # Set up light objects
    wavelengths = np.array([700])
    light_list = [
        objects.Light(wl, max_order_PWs=2, theta=0.0, phi=0.0) for wl in wavelengths
    ]
    light = light_list[0]

    # period must be consistent throughout simulation!!!
    period = 500
    NW_diameter = 120
    num_BMs = 40
    NW_array = objects.NanoStruct(
        "2D_array",
        period,
        NW_diameter,
        height_nm=2330,
        inclusion_a=materials.InP,
        background=materials.Air,
        loss=True,
        make_mesh_now=True,
        force_mesh=True,
        lc_bkg=0.07,
        lc2=1.5,
        lc3=2.0,
    )

    superstrate = objects.ThinFilm(
        period=period, height_nm="semi_inf", material=materials.Air, loss=False
    )

    substrate = objects.ThinFilm(
        period=period, height_nm="semi_inf", material=materials.SiO2, loss=False
    )

    ################ Evaluate each layer individually ##############
    sim_superstrate = superstrate.calc_modes(light)
    sim_NW_array = NW_array.calc_modes(light, num_BMs=num_BMs)
    sim_substrate = substrate.calc_modes(light)

    stack = Stack((sim_substrate, sim_NW_array, sim_superstrate))
    stack.calc_scat(pol="TE")
    stack_list = [stack]

    

    plotting.t_r_a_write_files(stack_list, wavelengths)
    
    return stack_list

    # # SAVE DATA AS REFERENCE
    # # Only run this after changing what is simulated - this
    # # generates a new set of reference answers to check against
    # # in the future
    # testing.save_reference_data("case_3", stack_list)


case = 3
result_files = (
    "Absorptance_stack0001.txt",
    "Lay_Absorb_0_stack0001.txt",
    "Lay_Trans_0_stack0001.txt",
    "Reflectance_stack0001.txt",
    "Transmittance_stack0001.txt",
)


def test_stack_list_matches_saved():
    stack_list = run_simulation()
    rtol = 1e-3
    atol = 1e-1
    testing.results_match_reference(case, rtol, atol, result_files)

    rtol = 1.5e8
    atol = 1.5e-3
    testing.check_results_simu_npz(case, rtol, atol, stack_list)
