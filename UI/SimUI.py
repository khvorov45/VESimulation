from tkinter import filedialog, Label, StringVar, Button, Tk
import sys
import subprocess
import os

class SelectDirectory:
    def __init__(self, master, label_text):
        self.directory = '.'
        self.lbl = Label(master, text = label_text)
        self.btn_text = StringVar()
        self.btn_text.set("Select")
        self.btn = Button(
            master, textvar = self.btn_text, command = self.select_directory
        )
    
    def place(self, nrow, ncol):
        self.lbl.grid(row=nrow, column=ncol, sticky='w')
        self.btn.grid(row=nrow, column=ncol+1, sticky='w')
    
    def select_directory(self):
        self.directory = filedialog.askdirectory()
        self.btn_text.set(self.directory)
    
    def get_current_dir(self):
        return self.directory

class UI:
    def __init__(self, root):
        self.script_sel_dir = SelectDirectory(root, "Location of scripts: ")
        self.save_sel_dir = SelectDirectory(root, "Save directory: ")


        btn_test_run = Button(
            root, text = "test run R script", command = self.sim_run
        )

        self.script_sel_dir.place(1,1)
        self.save_sel_dir.place(2,1)
        btn_test_run.grid(row=98,column=1, columnspan=2)
    
    def quit(self):
        sys.exit(0)
    
    def sim_run(self):
        script_path = os.path.join(
            self.script_sel_dir.get_current_dir(), "run_user_profile.R"
        )
        script_path = os.path.abspath(script_path)
        save_path = self.save_sel_dir.get_current_dir()
        save_path = os.path.abspath(save_path)
        
        call = [
            'Rscript', script_path, "--save_directory", save_path,
            "--profile_name","probabilistic_light"
        ]
        print(call)
        subprocess.call(call)

    def test_run(self):
        file_dir_path = os.path.dirname(os.path.realpath(__file__))
        os.chdir(file_dir_path)
        subprocess.call(['Rscript', 'test_script.R'])

root = Tk()
root.title('TN VE Simulation GUI')
UI(root)
root.mainloop()