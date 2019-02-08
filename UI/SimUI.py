from tkinter import filedialog, Label, StringVar, Button, Tk, Menubutton
from tkinter import Radiobutton
import sys
import subprocess
import os
import json

def read_filenames(script_dir):
    filenames_filepath = os.path.join(
        script_dir, "_file_index.json"
    )
    if not os.path.isfile(filenames_filepath):
        return None
    with open(filenames_filepath) as f:
        filenames = json.load(f)
    return filenames

class SelectDirectory:
    def __init__(self, master, label_text, ui_fun):
        self.init_dir = '.'
        self.directory = '.'
        self.lbl = Label(master, text = label_text)
        self.btn_text = StringVar()
        self.btn_text.set("Select")
        self.btn = Button(
            master, textvar = self.btn_text, command = self.select_directory
        )
        self.ui_fun = ui_fun
    
    def place(self, nrow, ncol):
        self.lbl.grid(row=nrow, column=ncol, sticky='w')
        self.btn.grid(row=nrow, column=ncol+1, sticky='w', columnspan = 3)
    
    def select_directory(self):
        self.directory = filedialog.askdirectory(initialdir = self.init_dir)
        self.btn_text.set(self.directory)
        self.ui_fun(self.directory)
    
    def get_current_dir(self):
        return self.directory
    
    def set_init_dir(self, dir):
        self.init_dir = dir

class OptionSelection:
    def __init__(self, master):
        self.master = master
        self.title = Label(master, text = 'Select script folder')
    
    def place(self, row, column):
        self.row = row
        self.col = column
        self.title.grid(row=row, column=column, sticky='w', columnspan = 4)
    
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

class UI:
    def __init__(self, root):
        self.save_dir = None
        self.script_dir = None
        self.script_sel_dir = SelectDirectory(
            root, "Location of scripts: ", self.update_script_dir
        )
        self.script_sel_dir.set_init_dir("C:\\Nexus\\VESimulation\\Scripts")
        self.save_sel_dir = SelectDirectory(
            root, "Save directory: ", self.update_save_dir
        )
        self.save_sel_dir.set_init_dir(
            "C:\\Users\\khvorov25\\Google Drive\\Doh\\VESim\\prob_run"
        )

        self.prof_selection = OptionSelection(root)

        btn_run = Button(
            root, text = "Run Simulation", command = self.sim_run
        )
        btn_print_call = Button(
            root, text = "Print Call", command = self.print_call
        )

        self.script_sel_dir.place(1,1)
        self.save_sel_dir.place(2,1)
        self.prof_selection.place(3,1)
        btn_run.grid(row=98, column=1)
        btn_print_call.grid(row=98, column=2)
        
    def update_save_dir(self, dir):
        if dir is None: return
        self.save_dir = dir
    
    def update_script_dir(self, dir):
        if dir is None: return
        self.script_dir = dir
        self.prof_selection.update_names(dir)
    
    def build_call(self):
        save_dir = self.save_dir
        if save_dir is None: save_dir = '.'
        script_dir = self.script_dir
        if script_dir is None: script_dir = '.'
        script_path = os.path.join(script_dir, "run_user_profile.R")
        filenames = read_filenames(script_dir)
        if filenames is None: return
        usage = self.read_usage(script_dir, filenames)
        save_dir_ind = usage["save_directory_ind"]
        profile_ind = usage["profile_ind"]
        cont_ind = usage["control_ind"]
        prof_name = self.prof_selection.get_current_profile()
        call = [
            'Rscript', script_path, cont_ind + save_dir_ind, save_dir,
            cont_ind + profile_ind, prof_name
        ]
        return call

    def sim_run(self):
        call = self.build_call()
        subprocess.call(call)
    
    def print_call(self):
        call = self.build_call()
        if call is not None: print(call)
    
    def read_usage(self, script_dir, filenames):
        def_folder = filenames["default_folder"]
        def_ind = filenames["default_ind"]
        config_ext = filenames["config_ext"]
        run_prof_usage_filepath = os.path.join(
            script_dir, def_folder, 
            def_ind +  "run_profile_usage" + "." + config_ext
        )
        with open(run_prof_usage_filepath) as f:
            run_prof_usage = json.load(f)
        return run_prof_usage

root = Tk()
root.title('TN VE Simulation GUI')
UI(root)
root.mainloop()