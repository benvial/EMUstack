"""
    test_case_0_thin_film_multistack.py is a simulation example for EMUstack.

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
Test simulation of a very simple structure;
a stack of lossy homogeneous dielectric films.
NOTE: This calculation is entirely analytical & should produce excellent
agreement on all machines.
"""


import numpy as np
import testing

from emustack import materials, objects, plotting
from emustack.stack import *

################ Light parameters #####################

# Set up light objects
wl_1 = 400
wl_2 = 1000
no_wl_1 = 3
wavelengths = np.linspace(wl_1, wl_2, no_wl_1)
light_list = [
    objects.Light(wl, max_order_PWs=1, theta=0.0, phi=0.0) for wl in wavelengths
]


################ Scattering matrices (for distinct layers) ##############
""" Calculate scattering matrices for each distinct layer.
Calculated in the order listed below, however this does not influence final
structure which is defined later
"""

# period must be consistent throughout simulation!!!
period = 1

superstrate = objects.ThinFilm(
    period=period,
    height_nm="semi_inf",
    material=materials.Material(3.5 + 0.0j),
    loss=False,
)

homo_film1 = objects.ThinFilm(
    period=period, height_nm=50, material=materials.Material(3.6 + 0.27j), loss=True
)

homo_film2 = objects.ThinFilm(
    period=period, height_nm=200, material=materials.Si_c, loss=True
)

mirror = objects.ThinFilm(
    period=period, height_nm=100, material=materials.Ag, loss=True
)

substrate = objects.ThinFilm(
    period=period, height_nm="semi_inf", material=materials.Air, loss=False
)

stack_list = []


def simulate_stack(light):

    ################ Evaluate each layer individually ##############
    sim_superstrate = superstrate.calc_modes(light)
    sim_homo_film1 = homo_film1.calc_modes(light)
    sim_homo_film2 = homo_film2.calc_modes(light)
    sim_mirror = mirror.calc_modes(light)
    sim_substrate = substrate.calc_modes(light)

    ################ Evaluate full solar cell structure ##############
    """ Now when defining full structure order is critical and
    solar_cell list MUST be ordered from bottom to top!
    """
    stack = Stack(
        (
            sim_substrate,
            sim_mirror,
            sim_homo_film1,
            sim_homo_film2,
            sim_homo_film1,
            sim_homo_film2,
            sim_superstrate,
        )
    )
    stack.calc_scat(pol="TM")

    return stack


def run_simulation():
    # Run in parallel across wavelengths.
    # This has to be in a setup_module otherwise nosetests will crash :(
    # pool = Pool(3)
    # stack_list = pool.map(simulate_stack, light_list)

    stack_list = [simulate_stack(l) for l in light_list]

    active_layer_nu = 3  # Specify which layer is the active one (where absorption generates charge carriers).
    plotting.t_r_a_plots(stack_list, active_layer_nu=active_layer_nu, save_txt=True)

    # # SAVE DATA AS REFERENCE
    # # Only run this after changing what is simulated - this
    # # generates a new set of reference answers to check against
    # # in the future
    # testing.save_reference_data("case_0", stack_list)
    return stack_list


case = 0
result_files = (
    "Absorptance_stack0001.txt",
    "Lay_Absorb_0_stack0001.txt",
    "Lay_Absorb_1_stack0001.txt",
    "Lay_Absorb_2_stack0001.txt",
    "Lay_Absorb_3_stack0001.txt",
    "Lay_Absorb_4_stack0001.txt",
    "Lay_Trans_0_stack0001.txt",
    "Lay_Trans_1_stack0001.txt",
    "Lay_Trans_2_stack0001.txt",
    "Lay_Trans_3_stack0001.txt",
    "Lay_Trans_4_stack0001.txt",
    "Reflectance_stack0001.txt",
    "Transmittance_stack0001.txt",
)


def test_stack_list_matches_saved():
    stack_list = run_simulation()
    rtol = 1e-6
    atol = 1e-6
    testing.results_match_reference(case, rtol, atol, result_files)
    rtol = 1e-6
    atol = 1e-6
    testing.check_results_simu_npz(case, rtol, atol, stack_list)
    plotting.plt.close("all")