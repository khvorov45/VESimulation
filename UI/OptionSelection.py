"""An array of profile names able to be selected"""

import os

from tkinter import Label, StringVar, Radiobutton, Button

from ui.utilities import read_filenames

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
        self.title = Label(master, text="Select script folder")
        self.new_btn = Button(
            self.master, text="New profile", command=self.make_new_profile
        )
        self.edit_btn = Button(
            self.master, text="Edit profile", command=self.edit_profile
        )
        self.prof_buttons = []
        self.prof_var = StringVar()
        self.prof_var.set("no profile selected")
        self.update(self.script_dir)
        self.row = 1
        self.col = 1
        self.filenames = None

    def place(self, row, column):
        """Places the top row of the entire widget"""
        self.row = row
        self.col = column
        self.title.grid(row=row, column=column, sticky="w")
        self.edit_btn.grid(row=row, column=column + 1, sticky="w")
        self.new_btn.grid(row=row, column=column + 2, sticky="w")

    def edit_profile(self):
        """Allows the user to edit a profile"""
        if self.filenames is None:
            print("select scripts directory")
            return
        cur_prof = self.prof_var.get()
        path_to_prof = os.path.join(
            self.script_dir, self.filenames["user_folder"], cur_prof
        )
        subprocess.Popen()

    def make_new_profile(self):
        """Allows the user to make a new profile"""

    def update(self, script_dir):
        """Attempts to find profile names and build profile buttons"""
        try:
            self.filenames = read_filenames(script_dir)
            if self.filenames is None:
                raise FileNotFoundError
            self.title['text'] = "_file_index.json found"
            self.title['fg'] = 'green'
        except FileNotFoundError:
            self.title['text'] = \
                "_file_index.json not found."
            self.title['fg'] = 'red'
            self.clear_prof_buttons()
            return
        path = os.path.join(script_dir, self.filenames["user_folder"])
        contents = os.listdir(path)
        prof_names = \
            [el for el in contents if os.path.isdir(os.path.join(path, el))]

        self.make_prof_buttons(prof_names)
        self.place_prof_buttons()

    def make_prof_buttons(self, prof_names):
        """Makes profile buttons"""
        for prof_name in prof_names:
            prof_button = Radiobutton(
                self.master, variable=self.prof_var,
                text=prof_name, value=prof_name
            )
            self.prof_buttons.append(prof_button)

    def place_prof_buttons(self):
        """Places profile buttons"""
        cur_row = self.row
        cur_col = self.col
        in_cur_row = 0
        for prof_button in self.prof_buttons:
            cur_row += 1
            in_cur_row += 1
            prof_button.grid(row=cur_row, column=cur_col, sticky='w')
            if in_cur_row == 5:
                in_cur_row = 0
                cur_row = self.row
                cur_col += 1

    def clear_prof_buttons(self):
        """Removes profile buttons"""
        for prof_button in self.prof_buttons:
            prof_button.destroy()
        self.prof_buttons = []
        self.prof_var.set("no profile selected")

    def get_current_profile(self):
        """Returns currently selected profile"""
        return self.prof_var.get()
