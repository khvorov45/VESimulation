import os
import json
import subprocess

from tkinter import Button

from SelectDirectory import SelectDirectory
from OptionSelection import OptionSelection
from utilities import read_filenames, read_usage

class UI:
    def __init__(self, root):
        
        self.save_dir = os.path.join(os.getcwd(),"VESimRun")
        self.script_dir = os.getcwd()
        
        self.script_sel_dir = SelectDirectory(
            root, "Location of scripts: ", self.update_script_dir, 
            self.script_dir
        )
        self.script_sel_dir.set_init_ask_dir("C:\\Nexus\\VESimulation\\Scripts")
        self.save_sel_dir = SelectDirectory(
            root, "Save directory: ", self.update_save_dir, 
            self.save_dir
        )
        self.save_sel_dir.set_init_ask_dir(
            "C:\\Users\\khvorov25\\Google Drive\\Doh\\VESim\\prob_run"
        )

        self.prof_selection = OptionSelection(root, self.script_dir)

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
        script_path = os.path.join(self.script_dir, "run_user_profile.R")
        filenames = read_filenames(self.script_dir)
        if filenames is None:
            print("_file_index.json not found in specified scripts folder") 
            return
        usage = read_usage(self.script_dir, filenames)
        save_dir_ind = usage["save_directory_ind"]
        profile_ind = usage["profile_ind"]
        cont_ind = usage["control_ind"]
        prof_name = self.prof_selection.get_current_profile()
        if prof_name == '': 
            print("Selelct a profile first")
            return
        call = [
            'Rscript', script_path, cont_ind + save_dir_ind, self.save_dir,
            cont_ind + profile_ind, prof_name
        ]
        return call

    def sim_run(self):
        call = self.build_call()
        if call is None: return
        subprocess.call(call)
    
    def print_call(self):
        call = self.build_call()
        if call is not None: print(call)