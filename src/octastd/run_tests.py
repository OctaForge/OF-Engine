from sys import stdout, exit
from os import listdir, remove, name as osname
from os.path import splitext, join as joinp
import subprocess as sp

# configuration - you can modify this

COMPILER = "c++"
CXXFLAGS = [
    "-std=c++11",
    "-Wall", "-Wextra",
    "-Wno-missing-braces", # clang false positive
    "-I."
]
COLORS = (osname != "nt")
TESTDIR = "tests"
SRCEXT = ".cc"

# don't modify past these lines

nsuccess = 0
nfailed  = 0

if COLORS:
    colors = {
        "red": "\033[91m",
        "green": "\033[92m",
        "blue": "\033[94m",
        "bold": "\033[1m",
        "end": "\033[0m"
    }
else:
    colors = { "red": "", "green": "", "blue": "", "bold": "", "end": "" }

def print_result(modname, fmsg = None):
    global nsuccess, nfailed
    if fmsg:
        print modname + ("...\t%(red)s%(bold)s(" + fmsg + ")%(end)s") % colors
        nfailed += 1
    else:
        print modname + "...\t%(green)s%(bold)s(success)%(end)s" % colors
        nsuccess += 1

for fname in listdir(TESTDIR):
    (modname, modext) = splitext(fname)

    if modext != SRCEXT:
        continue

    srcpath = joinp(TESTDIR, fname)
    exepath = joinp(TESTDIR, modname)

    pc = sp.Popen([ COMPILER, srcpath, "-o", exepath ] + CXXFLAGS,
        stdout = sp.PIPE, stderr = sp.STDOUT)
    stdout.write(pc.communicate()[0])

    if pc.returncode != 0:
        print_result(modname, "compile error")
        continue

    pc = sp.Popen(exepath, stdout = sp.PIPE, stderr = sp.STDOUT)
    stdout.write(pc.communicate()[0])

    if pc.returncode != 0:
        remove(exepath)
        print_result(modname, "runtime error")
        continue

    remove(exepath)
    print_result(modname)

print "\n%(blue)s%(bold)stesting done:%(end)s" % colors
print "%(green)sSUCCESS: " % colors + str(nsuccess) + colors["end"]
print "%(red)sFAILURE: " % colors + str(nfailed) + colors["end"]