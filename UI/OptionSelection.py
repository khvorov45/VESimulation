import os

from tkinter import Label, StringVar, Radiobutton, Button

from utilities import read_filenames

class OptionSelection:
    def __init__(self, master, start_dir):
        self.master = master
        self.title = Label(master, text = 'Select script folder')
        self.update_names(start_dir)
    
    def place(self, row, column):
        self.row = row
        self.col = column
        self.title.grid(row=row, column=column, sticky='w')
    
    def update_names(self, script_dir):
        try: 
            filenames = read_filenames(script_dir)
            if filenames is None: raise FileNotFoundError
            self.title['text'] = "_file_index.json found"
            self.title['fg'] = 'green'
        except FileNotFoundError:
            self.title['text'] = \
                "_file_index.json not found. Wrong scripts folder"
            self.title['fg'] = 'red'
            return
        path = os.path.join(script_dir, filenames["user_folder"])
        contents = os.listdir(path)
        prof_names = \
            [el for el in contents if os.path.isdir(os.path.join(path, el))]
        self.make_prof_buttons(prof_names)
        self.make_edit_btn()
        self.make_new_btn()
    
    def make_edit_btn(self):
        edit_btn = Button(self.master, text = "Edit profile")
        self.place_edit_btn(edit_btn)
    
    def place_edit_btn(self, edit_btn):
        edit_btn.grid(row = self.row, column = 4)
    
    def make_new_btn(self):
        new_btn = Button(self.master, text = "New profile")
        self.place_new_btn(new_btn)
    
    def place_new_btn(self, btn):
        btn.grid(row = self.row, column = 3)
    
    def make_prof_buttons(self, prof_names):
        prof_buttons = []
        self.prof_var = StringVar()
        for prof_name in prof_names:
            prof_button = Radiobutton(
                self.master, variable = self.prof_var, 
                text = prof_name, value = prof_name
            )
            prof_buttons.append(prof_button)
        self.place_prof_buttons(prof_buttons)
    
    def place_prof_buttons(self, prof_buttons):
        cur_row = self.row
        cur_col = self.col
        in_cur_row = 0
        for prof_button in prof_buttons:
            cur_row += 1
            in_cur_row += 1
            prof_button.grid(row=cur_row, column = cur_col, sticky='w')
            if in_cur_row == 5: 
                in_cur_row = 0
                cur_row = self.row
                cur_col += 1
    
    def get_current_profile(self):
        return self.prof_var.get()