from os import system as ossys

import numpy as np
from numpy.testing import assert_allclose as assert_ac
from numpy.testing import assert_equal
from objects import Simmo


def save_reference_data(casefile_name, stack_list):
    ref_stack_list = []
    for stack in stack_list:
        rstack = {"layers": []}
        for lay in stack.layers:
            rlay = {}
            rlay["R12"] = lay.R12
            rlay["T12"] = lay.T12
            rlay["R21"] = lay.R21
            rlay["T21"] = lay.T21
            rlay["k_z"] = lay.k_z
            if isinstance(rlay, Simmo):
                rlay["sol1"] = lay.sol1
            rstack["layers"].append(rlay)
        rstack["R_net"] = stack.R_net
        rstack["T_net"] = stack.T_net
        ref_stack_list.append(rstack)
    np.savez_compressed("ref/%s.npz" % casefile_name, stack_list=ref_stack_list)

    cp_cmd = "cp *.txt ref/%s/" % casefile_name
    ossys(cp_cmd)

    assert (
        False
    ), "Reference results saved successfully, \
but tests will now pass trivially so let's not run them now."


def results_match_reference(case, rtol, atol, result_files):
    for filename in result_files:
        reference = np.loadtxt(f"ref/case_{case}/" + filename)
        result = np.loadtxt(filename)
        np.testing.assert_allclose(result, reference, rtol, atol, filename)


def check_results_simu_npz(case, rtol, atol, stack_list):
    ref = np.load(f"ref/case_{case}.npz", allow_pickle=True, encoding="latin1")
    assert_equal(len(stack_list), len(ref["stack_list"]))
    for stack, rstack in zip(stack_list, ref["stack_list"]):
        assert_equal(len(stack.layers), len(rstack["layers"]))
        lbl_s = "wl = %f, " % stack.layers[0].light.wl_nm
        for i, (lay, rlay) in enumerate(zip(stack.layers, rstack["layers"])):
            lbl_l = lbl_s + "lay %i, " % i
            assert_ac(lay.R12, rlay["R12"], rtol, atol, lbl_l + "R12")
            assert_ac(lay.T12, rlay["T12"], rtol, atol, lbl_l + "T12")
            assert_ac(lay.R21, rlay["R21"], rtol, atol, lbl_l + "R21")
            assert_ac(lay.T21, rlay["T21"], rtol, atol, lbl_l + "T21")
            assert_ac(lay.k_z, rlay["k_z"], rtol, atol, lbl_l + "k_z")
            # TODO: yield assert_ac, lay.sol1, rlay['sol1']
        assert_ac(stack.R_net, rstack["R_net"], rtol, atol, lbl_s + "R_net")
        assert_ac(stack.T_net, rstack["T_net"], rtol, atol, lbl_s + "T_net")
