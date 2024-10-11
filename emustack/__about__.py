#!/usr/bin/env python


import importlib.metadata as metadata


def get_meta(metadata):
	data = metadata.metadata("emustack")
	__version__ = metadata.version("emustack")
	__author__ = data.get("author")
	__description__ = data.get("summary")
	return __version__, __author__, __description__, data


__version__, __author__, __description__, data = get_meta(metadata)
