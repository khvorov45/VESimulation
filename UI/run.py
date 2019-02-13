from tkinter import Tk
from UI import UI

def run_ui():
    root = Tk()
    root.title('TN VE Simulation GUI')
    UI(root)
    root.mainloop()

if __name__ == "__main__":
    run_ui()