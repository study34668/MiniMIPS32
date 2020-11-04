import os
import shutil

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
    name = str()
    for file in os.listdir(vivado_dir):
        if get_ext(file) == vivado_project_ext:
            name = get_name(file)
            break
    print('Vivado Project Name: %s' % name)
    src_dir = os.path.join(vivado_dir, name + vivado_new_src_path)
    for file in os.listdir(src_dir):
        src = os.path.join(src_dir, file)
        dst = os.path.join(verilog_dir, file)
        shutil.copy(src, dst)
        print('Copy %s' % file)
