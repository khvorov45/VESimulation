from tkinter import filedialog, Label, StringVar, Button, Tk, Menubutton, Menu
import sys
import subprocess
import os
import json

def read_filenames(script_dir):
    filenames_filepath = os.path.join(
        script_dir, "_file_index.json"
    )
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
        self.btn.grid(row=nrow, column=ncol+1, sticky='w')
    
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
        pass
    
    def place(self, row, column):
        pass
    
    def update_names(self, script_dir):
        pass

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

        self.script_sel_dir.place(1,1)
        self.save_sel_dir.place(2,1)
        self.prof_selection.place(3,1)
        btn_run.grid(row=98,column=1, columnspan=2)
    
    def update_save_dir(self, dir):
        self.save_dir = dir
    
    def update_script_dir(self, dir):
        self.script_dir = dir
        self.prof_selection.update_names(dir)

    def sim_run(self):
        if (self.save_dir is None) or (self.script_dir is None):
            raise Exception("Directory(ies) not selected")
        script_path = os.path.join(self.script_dir, "run_user_profile.R")
        filenames = read_filenames(self.script_dir)
        usage = self.read_usage(self.script_dir, filenames)
        save_dir_ind = usage["save_directory_ind"]
        
        profile_ind = usage["profile_ind"]
        
        cont_ind = usage["control_ind"]

        call = [
            'Rscript', script_path, cont_ind + save_dir_ind, self.save_dir,
            cont_ind + profile_ind, "probabilistic_light"
        ]
        print(call)
        subprocess.call(call)

    def read_profnames(self, script_dir):
        pass
    
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