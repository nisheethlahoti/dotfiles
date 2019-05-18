#!/usr/bin/env python3

from argparse import ArgumentParser
import code
import readline
import rlcompleter
import sys


def logged_input(prompt):
    inp = input(prompt)
    logfile.write(inp + '\n')
    return inp


parser = ArgumentParser(description='Interactive python console that logs all its input to a file')
parser.add_argument('logfile', help='File to log to')
parser.add_argument('args', nargs='*', help='Additional things to be passed on command line')
sys.path.append('.')
logfile = open(parser.parse_args().logfile, 'w')
console = code.InteractiveConsole(locals={'args': parser.parse_args().args})
console.raw_input = logged_input
readline.set_completer(rlcompleter.Completer(console.locals).complete)
readline.parse_and_bind("tab: complete")
banner = f'Python version {sys.version} Logged Console running on {sys.executable}'
console.interact(banner, f'Logged output to {logfile.name}')
