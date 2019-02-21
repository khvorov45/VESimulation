"""Checks that the selected scripts folder is correct"""

import os

from tkinter import Label

from ui.utilities import read_filenames

class ScriptValidator:
    """
    Checks scripts folder and creates a validation indicator

    Arguments:
        master: a tkinter object
    """
    def __init__(self, master):
        self.indicator = Label(master)

    def place(self, row, column):
        """Places the indicator"""
        self.indicator.grid(row=row, column=column, sticky="w")

    def validate_scripts(self, script_dir):
        """Performs the validation"""
        dir_valid = True
        filenames = read_filenames(script_dir)
        if filenames is None:
            print("_file_index.json not found")
            self.indicator["text"] = "Scripts directory invalid"
            self.indicator["fg"] = "red"
            dir_valid = False
            return
        script_names = filenames["scripts"]
        absent_scripts = []
        for script_name in script_names:
            script_name = script_name + "." + filenames["script_ext"]
            script_path = os.path.join(script_dir, script_name)
            script_path = os.path.abspath(script_path)
            if not os.path.isfile(script_path):
                absent_scripts.append(script_name)
                dir_valid = False
        if dir_valid:
            self.indicator["text"] = "Scripts directory valid"
            self.indicator["fg"] = "green"
            return
        self.indicator["text"] = "Scripts directory invalid"
        self.indicator["fg"] = "red"
        print(" ".join(absent_scripts) + "not found")
        return
