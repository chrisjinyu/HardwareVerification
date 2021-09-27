import glob
import subprocess
import argparse
import sys

BITWIDTH = 8
MAX_SHFT = 4

# Argument parser
parser = argparse.ArgumentParser()
# Top level design to test
parser.add_argument("top_level")
# Report file suffix
parser.add_argument('-s', help="Report file suffix", default='', action = 'store', dest='suffix')
# Parameters to test
parser.add_argument('-param', '-parameters', '-params', help="Desired parameter, separated by only a signle comma ex: BITWIDTH=8,MAX_SHFT=4", default='', action='store',dest='parameters')
# Ceiling/Floor Frequency (ADD FUNCTIONALITY LATER)
parser.add_argument('-c', help="Desired ceiling frequency to test, default 1", default=1, type='float', action='store', dest='ceiling')
parser.add_argument('-f', help="Desired floor frequency to test, default 0", default=0, type='float', action='store', dest='floor')
# Desired precision
parser.add_argument('-p', '-precision', help="Desired precision in MHz, will synthesize until difference with last test is below this", default=10, type='float',  action='store', dest='precision')

args = parser.parse_args()



#print("Currently under construction, might mess some things up. Exiting now.")
#sys.exit()




# Check if top level is specified
if args.top_level:
   top_level = args.top_level
else:
   print("ERROR: No top level specified. Exiting")
   sys.exit()

print("Finding best clock speed on module: " + top_level)
if args.parameters:
   print("Using parameters " + args.parameters)
if args.suffix:
   print("Using suffix: " + args.suffix)
print("Using ceiling and floor frequencies of " + ceiling + ", " + floor)

# Frequency specification file
SRC_FILE = './scripts/synth_common_stub.tcl'
# 
DST_FILE = './scripts/synth_common.tcl'
# Report file to check
REP_FILE = './dc_reports/' + top_level + '.timing'
AREA_FILE= './dc_reports/' + top_level + '.area'
# Final period value
PER_FILE = './' + top_level +  '_freq_report.txt' 
PARAM_FILE = './scripts/synth_design_stub.tcl'

# WJR: same as in test_bitwidth_shift, change this to modify synth_design_stub 
# instead of dc_synth

paramfile = open(PARAM_FILE, 'r+')
params = paramfile.readlines()
for item in params:
  if 'set hdl_params' in item:
     item = 'set hdl_params                "%s"\n' % args.parameters
#params[60] = 'elaborate $design_name -parameters %d,%d\n' % (i,j)
paramfile.close()
paramfile = open(PARAM_FILE, 'w')
paramfile.close()
paramfile = open(PARAM_FILE, 'w+')
for item in params:
   paramfile.write('%s' % item)

freq_area = ''

#Start at 1-GHz
current_freq = args.ceiling
last_violate = args.floor
last_met = args.ceiling

#Violation depth precision
max_violation = 50
violations = 0

while current_freq-last_violate>1/(args.precision*1000000):

    #initialize synth commons at current_freq
    freq_param = open(SRC_FILE, 'r+')
    #dest_param = open(DST_FILE, 'w+')

    for line in freq_param:
        if 'set period' in line:
            line = 'set period                    '+str(current_freq)+'\n'
            freq_param.write(line)
        else:
            freq_param.write(line)

    freq_param.close()
    #dest_param.close()

    #freq_param = open(SRC_FILE, 'w+')
    #dest_param = open(DST_FILE, 'r')

    #for line in dest_param:
    #   freq_param.write(line)

    #freq_param.close()
    #dest_param.close()

    subprocess.call('python ./scripts/run_synth.py '+top_level+ ' -s %s' %args.suffix, shell=True)

    report = open(REP_FILE, 'r')

    per = open(PER_FILE, 'w')
    per.write(str(last_met)+'\n'+str(last_violate)+'\n'+freq_area)
    per.close()

    for line in report:
        if 'slack (VIOLATED)' in line:
            violations = violations + 1
            last_violate = current_freq
            current_freq = (last_met + current_freq)/2.0 
            break
        if 'slack (MET)' in line:
            last_met = current_freq
            current_freq = (current_freq + last_violate)/2.0
            area = open(AREA_FILE, 'r')
            freq_area = area.read()
            area.close()
            break


per = open(PER_FILE, 'w')
per.write(str(last_met)+'\n'+str(last_violate)+'\n'+freq_area)
per.close()
