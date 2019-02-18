"""Runs the VE simulation UI when executed"""

from tkinter import Tk

from ui.uimain import UI

def run_sim_ui():
    """Runs UI"""
    root = Tk()
    root.title('TN VE Simulation GUI')
    UI(root)
    root.mainloop()

if __name__ == "__main__":
    run_sim_ui()
