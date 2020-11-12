import os
import sys
import shutil
import getopt

cwd = os.getcwd()
vivado_project_ext = 'xpr'
vivado_dir = os.path.join(cwd, 'vivado')
vivado_new_src_path = '.srcs/sources_1/new'
verilog_dir = os.path.join(cwd, 'verilog')


def get_ext(s):
    ext = ''
    for i in range(len(s) - 1, 0, -1):
        if s[i] != '.':
            ext = s[i] + ext
        else:
            break
    return ext


def get_name(s):
    for i in range(len(s) - 1, 0, -1):
        if s[i] == '.':
            return s[0 : i]
    return ''


if __name__ == '__main__':
    run_type = "before_commit"
    opts, args = getopt.getopt(sys.argv[1:], 'h', ["bc", "before_commit", "ap", "after_pull"])
    for opt, arg in opts:
        if opt == '-h':
            print('python git_helper.py [--bc --before_commit | --ap --after_pull]')
            sys.exit()
        elif opt in ("--bc", "--before_commit"):
            run_type = "before_commit"
        elif opt in ("--ap", "--after_pull"):
            run_type = "after_pull"

    if run_type == "after_pull":
        print("Are you sure to move files to vivado dir? (you can not undo this) (y/n)")
        sure = input()
        if sure != 'y':
            sys.exit()

    name = str()
    for file in os.listdir(vivado_dir):
        if get_ext(file) == vivado_project_ext:
            name = get_name(file)
            break
    print('Vivado Project Name: %s' % name)

    if run_type == "after_pull":
        src_dir = verilog_dir
        dst_dir = os.path.join(vivado_dir, name + vivado_new_src_path)
        print("Copy files from verilog to vivado")
    else:
        src_dir = os.path.join(vivado_dir, name + vivado_new_src_path)
        dst_dir = verilog_dir
        print("Copy files from vivado to verilog")
    for file in os.listdir(src_dir):
        src = os.path.join(src_dir, file)
        dst = os.path.join(dst_dir, file)
        shutil.copy(src, dst)
        print('Copy %s' % file)
