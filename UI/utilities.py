import json
import os

def read_filenames(script_dir):
    filenames_filepath = os.path.join(
        script_dir, "_file_index.json"
    )
    if not os.path.isfile(filenames_filepath):
        return None
    with open(filenames_filepath) as f:
        filenames = json.load(f)
    return filenames

def read_usage(script_dir, filenames):
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