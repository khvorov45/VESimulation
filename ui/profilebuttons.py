"""Makes the profile buttons"""

from tkinter import StringVar, Radiobutton

class ProfileButtons:
    """Represents the profile selection buttons"""
    def __init__(self, master):
        self.master = master
        self.prof_buttons = []
        self.prof_var = StringVar()
        self.empty_ind = "no profile selected"
        self.prof_var.set(self.empty_ind)

    def make(self, prof_names):
        """Makes profile buttons"""
        for prof_name in prof_names:
            prof_button = Radiobutton(
                self.master, variable=self.prof_var,
                text=prof_name, value=prof_name
            )
            self.prof_buttons.append(prof_button)

    def place(self, row, col):
        """Places profile buttons"""
        cur_row = row
        cur_col = col
        in_cur_row = 0
        for prof_button in self.prof_buttons:
            cur_row += 1
            in_cur_row += 1
            prof_button.grid(row=cur_row, column=cur_col, sticky='w')
            if in_cur_row == 5:
                in_cur_row = 0
                cur_row = row
                cur_col += 1

    def clear(self):
        """Removes profile buttons"""
        for prof_button in self.prof_buttons:
            prof_button.destroy()
        self.prof_buttons = []
        self.prof_var.set(self.empty_ind)

    def get_current_profile(self):
        """Returns currently selected profile"""
        return self.prof_var.get()
