"""Utility functions for the UI"""

import json
import os
import subprocess

def read_filenames(script_dir):
    """Reads _file_index.json inside specified directory"""
    filenames_filepath = os.path.join(
        script_dir, "_file_index.json"
    )
    filenames_filepath = os.path.abspath(filenames_filepath)
    if not os.path.isfile(filenames_filepath):
        return None
    with open(filenames_filepath) as ind_file:
        filenames = json.load(ind_file)
    return filenames

def read_usage(script_dir, filenames):
    """Reads run_profile_usage.json inside default settings in directory"""
    def_folder = filenames["default_folder"]
    def_ind = filenames["default_ind"]
    config_ext = filenames["config_ext"]
    run_prof_usage_filepath = os.path.join(
        script_dir, def_folder,
        def_ind +  "run_profile_usage" + "." + config_ext
    )
    with open(run_prof_usage_filepath) as use_file:
        run_prof_usage = json.load(use_file)
    return run_prof_usage

def wrap_string(phrase):
    """Inserts newline characters after some underscores in a long string"""
    und_indeces = []
    for ind, char in enumerate(phrase):
        if char == "_":
            und_indeces.append(ind)
    def cond(ind):
        if ind < 10:
            return False
        if (ind % 15 not in range(0, 4)) and (ind % 15 not in range(12, 15)):
            return False
        return True
    und_indeces = [ind for ind in und_indeces if cond(ind)]
    phrase_list = list(phrase)
    for cnt, ind in enumerate(und_indeces):
        phrase_list.insert(ind + 1 + cnt, "\n")
    phrase = "".join(phrase_list)
    return phrase

def open_folder_in_explorer(path_to_folder):
    """Opens a folder in explorer window"""
    path_to_folder = os.path.abspath(path_to_folder)
    subprocess.Popen(["explorer", path_to_folder])
