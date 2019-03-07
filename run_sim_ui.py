"""Runs the VE simulation UI when executed"""

import sys
import os

from tkinter import Tk

from ui import UI

def run_sim_ui(args):
    """Runs UI"""
    if len(args) > 1:
        scripts_dir = args[1]
    if not os.path.isdir(scripts_dir):
        scripts_dir = os.getcwd()
    root = Tk()
    root.title('TN VE Simulation GUI')
    UI(root, scripts_dir)
    root.mainloop()

if __name__ == "__main__":
    run_sim_ui(sys.argv)
