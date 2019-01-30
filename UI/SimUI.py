from tkinter import *
from tkinter import filedialog
import sys
import subprocess

class TestClass:
    def __init__(self, master):
        lbl_scr = Label(root, text = 'Location of scripts: ')
        lbl_scr.grid(row=1,column=1)
        
        self.btn_scr_text = StringVar()
        self.btn_scr_text.set("Select")        
        btn_scr = Button(root, textvar = self.btn_scr_text, command = self.select_directory)
        btn_scr.grid(row=1,column=2)
    
    def select_directory(self):
        directory = filedialog.askdirectory()
        self.btn_scr_text.set(directory)
    
    def quit(self):
        sys.exit()
    
    def run(self):
        subprocess.call(['Rscript', 'test_script.R'])

root = Tk()
root.title('TN VE Simulation GUI')
TestClass(root)
root.mainloop()