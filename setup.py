#!/usr/bin/env python
# -*- coding: utf-8 -*-

import setuptools

import setuptools
from distutils import log

import sys
import subprocess
import os


# from setuptools.command.install import install


# class FortranBuild(install):
#     """Customized setuptools build command."""

#     def run(self):
#         log.info("Building fortran...")
#         command = ["make", "emustack"]
#         if subprocess.call(command) != 0:
#             sys.exit(-1)
#         super().run()

# setuptools.setup(
#     cmdclass={
#         "install": FortranBuild,
#     },
# )




from contextlib import suppress
from pathlib import Path
from setuptools import Command, setup
from setuptools.command.build import build

class CustomCommand(Command):
    def initialize_options(self) -> None:
        self.bdist_dir = None

    def finalize_options(self) -> None:
        with suppress(Exception):
            self.bdist_dir = Path(self.get_finalized_command("bdist_wheel").bdist_dir)

    def run(self) -> None:
        log.info("Building fortran...")
        command = ["make", "emustack"]
        if subprocess.call(command) != 0:
            sys.exit(-1)
        # if self.bdist_dir:
        #     self.bdist_dir.mkdir(parents=True, exist_ok=True)
        #     (self.bdist_dir / "file.txt").write_text("hello world", encoding="utf-8")

class CustomBuild(build):
    sub_commands = [('build_custom', None)] + build.sub_commands

    command = ["make", "emustack"]

# setup(cmdclass={'build': CustomBuild, 'build_custom': CustomCommand})
setup()