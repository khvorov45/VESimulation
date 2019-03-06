"""SelectDirectory class for the UI"""

from tkinter import Label, StringVar, Button, filedialog

class SelectDirectory:
    """
    Creates a label with a button on the right of it.

    Arguments:
        master: a tkinter object
        label_text: text to be displayed next to the button
        ui_fun: function of the main class to connect the button command to
        init_sel_directory: initial selected directory
    """
    def __init__(self, master, label_text, ui_fun, init_sel_directory):
        self.directory = init_sel_directory
        self.lbl = Label(master, text=label_text)
        self.btn_text = StringVar()
        self.btn_text.set(str(self.directory))
        self.btn = Button(
            master, textvar=self.btn_text, command=self.select_directory
        )
        self.ui_fun = ui_fun

    def place(self, nrow, ncol):
        """Places the element on the master"""
        self.lbl.grid(row=nrow, column=ncol, sticky='w')
        self.btn.grid(row=nrow, column=ncol + 1, sticky='w', columnspan=3)

    def select_directory(self):
        """Command the button is bound to"""
        self.directory = filedialog.askdirectory(initialdir=self.directory)
        self.btn_text.set(self.directory)
        self.update_directory()

    def update_directory(self):
        """Calls the associated main ui function with current directory"""
        self.ui_fun(self.directory)

    def get_current_dir(self):
        """Returns current directory"""
        return self.directory
