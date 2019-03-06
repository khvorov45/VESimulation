"""Main UI class"""

import os
import subprocess

from tkinter import Button

from ui.selectdirectory import SelectDirectory
from ui.optionselection import OptionSelection
from ui.utilities import read_filenames, read_usage
from ui.scriptvalidator import ScriptValidator

class UI:
    """
    Creates the entire UI.

    Arguments:
        root: Tk object

    Attributes:
        save_dir: directory where the generated data is to be saved
        script_dir: directory with R scripts of VE simulation
        ...
    """
    def __init__(self, root, scripts_dir):

        self.save_dir = os.path.join(os.getcwd(), "VESimRun")

        self.script_dir = scripts_dir

        self.script_validatior = ScriptValidator(root)

        self.script_sel_dir = SelectDirectory(
            root, "Location of scripts: ", self.update_script_dir,
            self.script_dir
        )

        self.save_sel_dir = SelectDirectory(
            root, "Save directory: ", self.update_save_dir,
            self.save_dir
        )

        self.prof_selection = OptionSelection(root, self.script_dir)

        btn_run = Button(
            root, text="Run Simulation", command=self.sim_run
        )
        btn_print_call = Button(
            root, text="Print Call", command=self.print_call
        )

        self.update_script_dir(self.script_dir)

        self.script_sel_dir.place(1, 1)
        self.save_sel_dir.place(2, 1)
        self.prof_selection.place(3, 1)
        self.script_validatior.place(99, 1)
        btn_run.grid(row=98, column=1, sticky="w")
        btn_print_call.grid(row=98, column=2, sticky="w")

    def update_save_dir(self, dir_selected):
        """Updates save_dir in response to user choice"""
        if dir is None:
            return
        dir_selected = os.path.abspath(dir_selected)
        self.save_dir = dir_selected

    def update_script_dir(self, dir_selected):
        """Updates script_dir in response to user choice"""
        if dir is None:
            return
        dir_selected = os.path.abspath(dir_selected)
        self.script_dir = dir_selected
        self.script_validatior.validate_scripts(self.script_dir)
        self.prof_selection.update(dir_selected)

    def build_call(self):
        """Creates the call the system will be asked to execute"""
        script_path = os.path.join(self.script_dir, "run_user_profile.R")
        filenames = read_filenames(self.script_dir)
        if filenames is None:
            print("_file_index.json not found in specified scripts folder")
            return None
        usage = read_usage(self.script_dir, filenames)
        save_dir_ind = usage["save_directory_ind"]
        profile_ind = usage["profile_ind"]
        cont_ind = usage["control_ind"]
        prof_name = self.prof_selection.btns.get_current_profile()
        if prof_name == self.prof_selection.btns.empty_ind:
            print("Selelct a profile first")
            return None
        call = [
            'Rscript', script_path, cont_ind + save_dir_ind, self.save_dir,
            cont_ind + profile_ind, prof_name
        ]
        return call

    def sim_run(self):
        """Asks the system to execute comands to run the simulation"""
        call = self.build_call()
        if call is None:
            return
        subprocess.call(call)

    def print_call(self):
        """Prints the call of build_call"""
        call = self.build_call()
        if call is not None:
            print(call)
