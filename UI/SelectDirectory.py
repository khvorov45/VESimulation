from tkinter import Label, StringVar, Button, filedialog

class SelectDirectory:
    def __init__(self, master, label_text, ui_fun, shown_directory):
        self.init_ask_dir = '.'
        self.directory = shown_directory
        self.lbl = Label(master, text = label_text)
        self.btn_text = StringVar()
        self.btn_text.set(str(self.directory))
        self.btn = Button(
            master, textvar = self.btn_text, command = self.select_directory
        )
        self.ui_fun = ui_fun
    
    def place(self, nrow, ncol):
        self.lbl.grid(row=nrow, column=ncol, sticky='w')
        self.btn.grid(row=nrow, column=ncol+1, sticky='w', columnspan = 3)
    
    def select_directory(self):
        self.directory = filedialog.askdirectory(initialdir = self.init_ask_dir)
        self.btn_text.set(self.directory)
        self.update_directory()

    def update_directory(self):
        self.ui_fun(self.directory)
    
    def get_current_dir(self):
        return self.directory
    
    def set_init_ask_dir(self, dir):
        self.init_ask_dir = dir