# This source file is part of the Greatdori! open source project
#
# Copyright (c) 2025 the Greatdori! project authors
# Licensed under Apache License v2.0
#
# This source file is initially from the Swift.org open source project
# Licensed under Apache License v2.0 with Runtime Library Exception
# Edited by the Greatdori! open source project
#
# See https://greatdori.memz.top/LICENSE.txt for license information
# See https://greatdori.memz.top/CONTRIBUTORS.txt for the list of Greatdori! project authors

import os.path

# --------------------------------------------------------------------------------------
# Project Paths


MODULE_PATH = os.path.abspath(os.path.dirname(__file__))

BUILD_DORI_PATH = os.path.dirname(MODULE_PATH)

UTILS_PATH = os.path.dirname(BUILD_DORI_PATH)

PROJECT_PATH = os.path.dirname(UTILS_PATH)


# --------------------------------------------------------------------------------------
# Helpers

def _is_greatdori_checkout(dori_path):
    """Returns true if the given swift_path is a valid Greatdori checkout, false otherwise.

    NOTE: This is a very naive validation, checking only for the existence of a few
    known files.
    """

    if not os.path.exists(os.path.join(dori_path, "utils")):
        return False

    if not os.path.exists(os.path.join(dori_path, "Greatdori.xcodeproj")):
        return False

    return True


def _get_dori_source_root(dori_path, env=None):
    """Returns the Greatdori source root or None if one cannot be determined.

    Users are able to manually override the source root by setting the DORI_SOURCE_ROOT
    environment variable. If that cannot be found then this function will infer the source root.

    Building standalone means Greatdori will be checked out as a peer of DoriKit and the
    enclosing directory is the source root.

        source-root/
        |- DoriKit/
        |- Greatdori/
        | ...
    """

    env = env or {}

    # Check the environment first.
    if "DORI_SOURCE_ROOT" in env:
        return env["DORI_SOURCE_ROOT"]

    # Assert we are in a valid Greatdori checkout.
    if not _is_greatdori_checkout(dori_path):
        return None

    source_root = os.path.dirname(dori_path)

    return source_root


def _get_dori_repo_name(dori_path, env=None):
    """Returns the Greatdori repo name or None if it cannot be determined.

    Users are able to manually override the repo name by setting the DORI_REPO_NAME
    environment variable. If that cannot be found then this function returns the name
    of the given Greatdori path or None if it is not a valid Greatdori checkout.
    """

    env = env or {}

    if "DORI_REPO_NAME" in env:
        return env["DORI_REPO_NAME"]

    if not _is_greatdori_checkout(dori_path):
        return None

    return os.path.basename(dori_path)


# --------------------------------------------------------------------------------------
# Greatdori Source and Build Roots


# Set DORI_SOURCE_ROOT in your environment to control where the sources are found.
DORI_SOURCE_ROOT = _get_dori_source_root(PROJECT_PATH, env=os.environ)

# Set DORI_REPO_NAME in your environment to control the name of the swift directory
# name that is used.
DORI_REPO_NAME = _get_dori_repo_name(PROJECT_PATH, env=os.environ)
