"""An array of profile names able to be selected"""

import os

from tkinter import Button
from shutil import copy

from .profilebuttons import ProfileButtons
from .utilities import read_filenames, open_folder_in_explorer

class OptionSelection:
    """
    Creates the entire array for profile selection.

    Arguments:
        master: a tkinter object
        start_dir: initial directory to scan for profile names
    """
    def __init__(self, master, start_dir):
        self.master = master
        self.script_dir = start_dir
        self.new_btn = Button(
            self.master,
            text="New from selected",
            command=self.make_new_profile
        )
        self.edit_btn = Button(
            self.master, text="Edit selected", command=self.edit_profile
        )
        self.btns = ProfileButtons(master)
        self.filenames = None
        self.row = 1
        self.col = 1
        self.update(self.script_dir)

    def place(self, row, column):
        """Places the top row of the entire widget"""
        self.row = row
        self.col = column
        self.edit_btn.grid(row=row, column=column, sticky="w")
        self.new_btn.grid(row=row, column=column + 1, sticky="w")
        self.btns.place(row=row + 1, col=column)

    def edit_profile(self):
        """Allows the user to edit a profile"""
        path_to_prof = self.get_selected_profile_path()
        if path_to_prof is None:
            return
        open_folder_in_explorer(path_to_prof)

    def make_new_profile(self):
        """Allows the user to make a new profile from selected"""
        cur_prof_path = self.get_selected_profile_path()
        if cur_prof_path is None:
            return
        cur_prof_name = os.path.basename(cur_prof_path)
        new_name = input("Enter name >")
        new_path = os.path.join(
            self.script_dir, self.filenames["user_folder"], new_name
        )
        new_path = os.path.abspath(new_path)
        if not os.path.exists(new_path):
            os.makedirs(new_path)
        for file_name in os.listdir(cur_prof_path):
            file_path = os.path.join(cur_prof_path, file_name)
            file_path = os.path.abspath(file_path)
            copy(file_path, new_path)
        print(
            "Created profile", new_name,
            "and initialised with", cur_prof_name, "settings"
        )
        open_folder_in_explorer(new_path)
        self.update(self.script_dir)

    def get_selected_profile_path(self):
        """Returns filepath to selected profile"""
        if self.filenames is None:
            print("select scripts directory")
            return None
        cur_prof = self.btns.get_current_profile()
        if cur_prof == "no profile selected":
            print("select a profile")
            return None
        path_to_prof = os.path.join(
            self.script_dir, self.filenames["user_folder"], cur_prof
        )
        path_to_prof = os.path.abspath(path_to_prof)
        return path_to_prof

    def update(self, script_dir):
        """Attempts to find profile names and build profile buttons"""
        self.script_dir = script_dir
        self.btns.clear()
        self.filenames = read_filenames(self.script_dir)
        if self.filenames is None:
            return
        path = os.path.join(self.script_dir, self.filenames["user_folder"])
        path = os.path.abspath(path)
        if not os.path.isdir(path):
            return
        contents = os.listdir(path)
        prof_names = \
            [el for el in contents if os.path.isdir(os.path.join(path, el))]
        self.btns.make(prof_names)
        self.btns.place(self.row + 1, self.col)
