"""Material properties.

materials.py is a subroutine of EMUstack that defines Material objects,
these represent dispersive lossy refractive indices and possess
methods to interpolate n from tabulated data.

Copyright (C) 2015  Bjorn Sturmberg, Kokou Dossou, Felix Lawrence

EMUstack is free software: you can redistribute it and/or modify
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

import matplotlib.pyplot as plt
import numpy as np
from scipy.interpolate import interp1d

from . import paths

data_location = paths.data_path


class Material:
	"""Represents a material with a refractive index n.

	If the material is dispersive, the refractive index at a given
	wavelength is calculated by linear interpolation from the
	initially given data `n`. Materials may also have `n` calculated
	from a Drude model with input parameters.

	Args:
	    n  : Either a scalar refractive index,
	        an array of values `(wavelength, n)`, or
	        `(wavelength, real(n), imag(n))`,
	        or omega_p, omega_g, eps_inf for Drude model.

	Currently included materials are;

	.. tabularcolumns:: |c|c|c|

	+--------------------+------------+------------------------+
	| **Semiconductors** | **Metals** | **Transparent oxides** |
	+--------------------+------------+------------------------+
	|    Si_c            |  Au        |   TiO2                 |
	+--------------------+------------+------------------------+
	|    Si_a            |  Au_Palik  |   TiO2_anatase         |
	+--------------------+------------+------------------------+
	|    SiO2            |  Ag        |   ITO                  |
	+--------------------+------------+------------------------+
	|    CuO             |  Ag_Palik  |   ZnO                  |
	+--------------------+------------+------------------------+
	|    CdTe            |  Cu        |   SnO2                 |
	+--------------------+------------+------------------------+
	|    FeS2            |  Cu_Palik  |   FTO_Wenger           |
	+--------------------+------------+------------------------+
	|    Zn3P2           |  Al        |   FTO_Wengerk5         |
	+--------------------+------------+------------------------+
	|    AlGaAs          |            |                        |
	+--------------------+------------+------------------------+
	|    Al2O3           |            |                        |
	+--------------------+------------+------------------------+
	|    Al2O3_PV        |            |                        |
	+--------------------+------------+------------------------+
	|    GaAs            |            |                        |
	+--------------------+------------+------------------------+
	|    InGaAs          | **Drude**  | **Other**              |
	+--------------------+------------+------------------------+
	|    Si3N4           |  Au_drude  |   Air                  |
	+--------------------+------------+------------------------+
	|    MgF2            |            |   H2O                  |
	+--------------------+------------+------------------------+
	|    InP             |            |   Glass                |
	+--------------------+------------+------------------------+
	|    InAs            |            |   Spiro                |
	+--------------------+------------+------------------------+
	|    GaP             |            |   Spiro_nk             |
	+--------------------+------------+------------------------+
	|    Ge              |            |                        |
	+--------------------+------------+------------------------+
	|    AlN             |            |                        |
	+--------------------+------------+------------------------+
	|    GaN             |            |                        |
	+--------------------+------------+------------------------+
	|    MoO3            |            |                        |
	+--------------------+------------+------------------------+
	|    ZnS             |            |                        |
	+--------------------+------------+------------------------+
	|    AlN_PV          |            |                        |
	+--------------------+------------+------------------------+
	|                    |            | **Experimental** incl. |
	+--------------------+------------+------------------------+
	|                    |            |    CH3NH3PbI3          |
	+--------------------+------------+------------------------+
	|                    |            |    Sb2S3               |
	+--------------------+------------+------------------------+
	|                    |            |    Sb2S3_ANU2014       |
	+--------------------+------------+------------------------+
	|                    |            |    Sb2S3_ANU2015       |
	+--------------------+------------+------------------------+
	|                    |            |    GO_2014             |
	+--------------------+------------+------------------------+
	|                    |            |    GO_2015             |
	+--------------------+------------+------------------------+
	|                    |            |    rGO_2015            |
	+--------------------+------------+------------------------+
	|                    |            |    SiON_Low            |
	+--------------------+------------+------------------------+
	|                    |            |    SiON_High           |
	+--------------------+------------+------------------------+
	|                    |            |    Low_Fe_Glass        |
	+--------------------+------------+------------------------+
	|                    |            |    Perovskite_00       |
	+--------------------+------------+------------------------+
	|                    |            |    Perovskite          |
	+--------------------+------------+------------------------+
	|                    |            |    Perovskite_b2b      |
	+--------------------+------------+------------------------+
	|                    |            |    Ge_Doped            |
	+--------------------+------------+------------------------+
	"""

	def __init__(self, n):
		if () == np.shape(n):
			# n is a scalar, the medium is non-dispersive.
			self._n = lambda x: n
			self.data_wls = None
			self.data_ns = n
		elif np.shape(n) == (3,):
			# we will calculate n from the Drude model with input 
			# omega_p, omega_g, eps_inf values
			c = 299792458
			omega_plasma = n[0]
			omega_gamma = n[1]
			eps_inf = n[2]
			self.data_wls = "Drude"
			self.data_ns = [omega_plasma, omega_gamma, eps_inf, c]
			self._n = lambda x: np.sqrt(
				self.data_ns[2]
				- self.data_ns[0] ** 2
				/ (
					((2 * np.pi * self.data_ns[3]) / (x * 1e-9)) ** 2
					+ 1j
					* self.data_ns[1]
					* (2 * np.pi * self.data_ns[3])
					/ (x * 1e-9)
				)
			)
			if np.imag(self._n) < 0:
				self._n *= -1

		elif np.shape(n) >= (2, 1):
			self.data_wls = n[:, 0]
			if len(n[0]) == 2:
				# n is an array of wavelengths and (possibly-complex)
				# refractive indices.
				self.data_ns = n[:, 1]
			elif len(n[0]) == 3:
				self.data_ns = n[:, 1] + 1j * n[:, 2]
			else:
				raise ValueError
			# Do cubic interpolation if we get the chance
			# if len(self.data_wls) > 3:
			#     self._n = interp1d(self.data_wls, self.data_ns, 'cubic')
			# else:
			self._n = interp1d(self.data_wls, self.data_ns)
		# else:
		#     raise ValueError, "You must either set a constant refractive
		#         index, provide tabulated data, or Drude parameters"

	def n(self, wl_nm):
		"""Return n for the specified wavelength."""
		return self._n(wl_nm)

	def __getstate__(self):
		"""Can't pickle self._n, so remove it from what is pickled."""
		d = self.__dict__.copy()
		d.pop("_n")
		return d

	def __setstate__(self, d):
		"""Recreate self._n when unpickling."""
		self.__dict__ = d
		if None is self.data_wls:
			self._n = lambda x: self.data_ns
		elif isinstance(self.data_wls, str) and self.data_wls == "Drude":
			self._n = lambda x: np.sqrt(
				self.data_ns[2]
				- self.data_ns[0] ** 2
				/ (
					((2 * np.pi * self.data_ns[3]) / (x * 1e-9)) ** 2
					+ 1j
					* self.data_ns[1]
					* (2 * np.pi * self.data_ns[3])
					/ (x * 1e-9)
				)
			)
			if np.imag(self._n) < 0:
				self._n *= -1
		else:
			self._n = interp1d(self.data_wls, self.data_ns)


def plot_n_data(data_name):
	"""
	Plot refractive index data for a given material.

	Parameters
	----------
	data_name : str
		Name of the material to plot, without the ".txt" extension.

	Notes
	-----
	This function will save a plot to a file with the name
	"{data_name}_n.pdf". The plot will have real(n) on the left y-axis
	and imaginary(n) on the right y-axis.
	"""
	data = np.loadtxt(data_location + f"{data_name}.txt")
	wls = data[:, 0]
	Re_n = data[:, 1]
	Im_n = data[:, 2]
	fig = plt.figure(figsize=(5, 2))
	ax1 = fig.add_subplot(1, 1, 1)
	ax1.plot(wls, Re_n, "k", linewidth=2)
	ax1.set_ylabel(r"Re(n)")
	ax2 = ax1.twinx()
	ax2.plot(wls, Im_n, "r--", linewidth=2)
	ax2.set_ylabel(r"Im(n)")
	ax2.spines["right"].set_color("red")
	ax2.yaxis.label.set_color("red")
	ax2.tick_params(axis="y", colors="red")
	ax1.set_xlim((wls[0], wls[-1]))
	plt.savefig(f"{data_name}_n")


Air = Material(1.00 + 0.0j)
H2O = Material(np.loadtxt(f"{data_location}H2O.txt"))
# G. M. Hale and M. R. Querry. doi:10.1364/AO.12.000555


# Transparent oxides
TiO2 = Material(np.loadtxt(f"{data_location}TiO2.txt"))
# Filmetrics.com
TiO2_anatase = Material(np.loadtxt(f"{data_location}TiO2_anatase.txt"))
# 500C anneal PV Lighthouse doi:/10.1016/S0927-0248(02)00473-7
ITO = Material(np.loadtxt(f"{data_location}ITO.txt"))
# Filmetrics.com
ZnO = Material(np.loadtxt(f"{data_location}ZnO.txt"))
# Z. Holman 2012 unpublished http://www.pvlighthouse.com.au/resources/photovoltaic%20materials/refractive%20index/refractive%20index.aspx


# Semiconductors
Si_c = Material(np.loadtxt(f"{data_location}Si_c.txt"))
# M. Green Prog. PV 1995 doi:10.1002/pip.4670030303
Si_a = Material(np.loadtxt(f"{data_location}Si_a.txt"))
SiO2 = Material(np.loadtxt(f"{data_location}SiO2.txt"))
CuO = Material(np.loadtxt(f"{data_location}CuO.txt"))
CdTe = Material(np.loadtxt(f"{data_location}CdTe.txt"))
FeS2 = Material(np.loadtxt(f"{data_location}FeS2.txt"))
Zn3P2 = Material(np.loadtxt(f"{data_location}Zn3P2.txt"))
Sb2S3 = Material(np.loadtxt(f"{data_location}Sb2S3.txt"))
AlGaAs = Material(np.loadtxt(f"{data_location}AlGaAs.txt"))
ZnS = Material(np.loadtxt(f"{data_location}ZnS.txt"))
SnO2 = Material(np.loadtxt(f"{data_location}SnO2.txt"))
Glass = Material(np.loadtxt(f"{data_location}Soda_lime_glass_nk_Pil.txt"))
# PV lighthouse, unpublished
Al2O3 = Material(np.loadtxt(f"{data_location}Al2O3.txt"))
# http://refractiveindex.info/?shelf=main&book=Al2O3&page=Malitson-o
Al2O3_PV = Material(np.loadtxt(f"{data_location}Al2O3_PV.txt"))
# PV lighthouse
GaAs = Material(np.loadtxt(f"{data_location}GaAs.txt"))
# http://www.filmetrics.com/refractive-index-database/GaAs/Gallium-Arsenide
InGaAs = Material(np.loadtxt(f"{data_location}InGaAs.txt"))
# http://refractiveindex.info/?group=CRYSTALS&material=InGaAs
Si3N4 = Material(np.loadtxt(f"{data_location}Si3N4.txt"))
# http://www.filmetrics.com/refractive-index-database/Si3N4/Silicon-Nitride-SiN
MgF2 = Material(np.loadtxt(f"{data_location}MgF2.txt"))
# http://www.filmetrics.com/refractive-index-database/MgF2/Magnesium-Fluoride
InP = Material(np.loadtxt(f"{data_location}InP.txt"))
InAs = Material(np.loadtxt(f"{data_location}InAs.txt"))
# Filmetrics.com
GaP = Material(np.loadtxt(f"{data_location}GaP.txt"))
# Filmetrics.com
GaN = Material(np.loadtxt(f"{data_location}GaN.txt"))
# http://www.filmetrics.com/refractive-index-database/GaN/Gallium-Nitride
AlN = Material(np.loadtxt(f"{data_location}AlN.txt"))
# http://www.filmetrics.com/refractive-index-database/AlN/Aluminium-Nitride
Ge = Material(np.loadtxt(f"{data_location}Ge.txt"))
# http://www.filmetrics.com/refractive-index-database/Ge/Germanium
MoO3 = Material(np.loadtxt(f"{data_location}MoO3.txt"))
# doi:10.1103/PhysRevB.88.115141
Spiro = Material(np.loadtxt(f"{data_location}Spiro.txt"))
# doi:10.1364/OE.23.00A263
Spiro_nk = Material(np.loadtxt(f"{data_location}Spiro_nk_Filipic.txt"))
# Extended Filipic data
FTO_Wenger = Material(np.loadtxt(f"{data_location}FTO_Wenger.txt"))
# doi:10.1021/jp111565q
FTO_Wengerk5 = Material(np.loadtxt(f"{data_location}FTO_Wengerk5.txt"))
# doi:10.1021/jp111565q
AlN_PV = Material(np.loadtxt(f"{data_location}AlN_PV.txt"))
# PV lighthouse doi:10.1002/pssr.201307153

# Metals
Au = Material(np.loadtxt(f"{data_location}Au_JC.txt"))
# Johnson Christy
Au_Palik = Material(np.loadtxt(f"{data_location}Au_Palik.txt"))
# Palik
Ag = Material(np.loadtxt(f"{data_location}Ag_JC.txt"))
# Johnson Christy
Ag_Palik = Material(np.loadtxt(f"{data_location}Ag_Palik.txt"))
# Palik
Cu = Material(np.loadtxt(f"{data_location}Cu_JC.txt"))
# Johnson Christy
Cu_Palik = Material(np.loadtxt(f"{data_location}Cu_Palik.txt"))
# Palik
Al = Material(np.loadtxt(f"{data_location}Al.txt"))
# McPeak ACS Photonics 2015 http://dx.doi.org/10.1021/ph5004237


# Drude model
# Need to provide [omega_plasma, omega_gamma, eplison_infinity]
Au_drude = Material([1.36e16, 1.05e14, 9.5])
# Johnson Christy


# Less Validated
CH3NH3PbI3 = Material(np.loadtxt(f"{data_location}CH3NH3PbI3.txt"))
# doi:10.1021/jz502471h - EPFL
Sb2S3_ANU2014 = Material(np.loadtxt(f"{data_location}Sb2S3_ANU2014.txt"))
# measured at Australian National Uni.
Sb2S3_ANU2015 = Material(np.loadtxt(f"{data_location}Sb2S3_ANU2015.txt"))
# measured at Australian National Uni.
GO_2014 = Material(np.loadtxt(f"{data_location}GO_2014.txt"))
# Graphene Oxide measured at Swinbourne Uni.
GO_2015 = Material(np.loadtxt(f"{data_location}GO_2015.txt"))
# Graphene Oxide measured at Swinbourne Uni.
rGO_2015 = Material(np.loadtxt(f"{data_location}rGO_2015.txt"))
# reduced Graphene Oxide measured at Swinbourne Uni.
SiON_Low = Material(np.loadtxt(f"{data_location}SiON_Low.txt"))
# measured at Australian National Uni.
SiON_High = Material(np.loadtxt(f"{data_location}SiON_High.txt"))
# measured at Australian National Uni.

Low_Fe_Glass = Material(np.loadtxt(f"{data_location}Low_Fe_Glass_Pil.txt"))
# PV lighthouse, unpublished Pilkington data
Perovskite_00 = Material(np.loadtxt(f"{data_location}Perovskite_E_u_00.txt"))
# doi:10.1021/jz502471h
Perovskite = Material(
	np.loadtxt(f"{data_location}Perovskite_Loper_E_u_080.txt")
)
# doi:10.1021/jz502471h, with extended urbach tail for parasitic absorption
Perovskite_b2b = Material(np.loadtxt(f"{data_location}Perovskite_b2b_nk.txt"))
# The above data for n, k data just for band to band transitions
# http://pubs.acs.org/doi/suppl/10.1021/acs.jpclett.5b00044/suppl_file/jz5b00044_si_001.pdf
Ge_Doped = Material(np.loadtxt(f"{data_location}Ge_Doped.txt"))
# doi:10.1109/IRMMW-THz.2014.6956438, heavily doped Germanium for 
# mid-infrared plasmonics
ITO_annealed = Material(np.loadtxt(f"{data_location}ITO_anneal_Gen_Osc.txt"))
# ANU measurement
