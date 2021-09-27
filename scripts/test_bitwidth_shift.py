import glob
import subprocess

# WJR: I'd like to expand this to be able to handle any module
# and any set of parameters, but we can work on that later.

#Parameter specification file
PARAM_FILE = './scripts/synth_design_stub.tcl'

#clock timing specifiers
SRC_FILE = './scripts/synth_common_stub.tcl'
DST_FILE = './scripts/synth_common.tcl'

#stat files
AREA_FILE = './dc_reports/sc2bin_BWSHFT.area'
PWR_FILE  = './dc_reports/sc2bin_BWSHFT.power_verb'

#report file
REP_FILE = './bw_shft_report.txt'

current_freq = 5

area_amt = ''

pwr_amt1 = ''
pwr_amt2 = ''
small_pwr = 0

min_bw = 4
max_bw = 12
min_shft = 0
max_shft = 8

#Set timing to desired
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

# WJR: why are you parsing those files the second time?
#for line in dest_param:
#    freq_param.write(line)

#freq_param.close()
#dest_param.close()

for i in range (min_bw, max_bw+1, 1):
    for j in range (min_shft, max_shft+1, 1):
        # WJR: Ideally I'd prefer if you didn't modify dc_synth.tcl at all
        # I modified dc_synth and synth_design_stub to use a variable
        # called hdl_params. You should change your code below to 
        # modify synth_design_stub instead of dc_synth.tcl
        paramfile = open(PARAM_FILE, 'r+')
        params = paramfile.readlines()
        for item in params:
           if 'set hdl_params' in item:
              item = 'set hdl_params                "%d,%d"\n' % (i,j)
        #params[60] = 'elaborate $design_name -parameters %d,%d\n' % (i,j)
        paramfile.close()
        paramfile = open(PARAM_FILE, 'w')
        paramfile.close()
        paramfile = open(PARAM_FILE, 'w+')
        for item in params:
            paramfile.write('%s' % item)
        paramfile.close()

        subprocess.call('python ./scripts/run_synth.py sc2bin -s %s' % '_BWSHFT', shell = True)
        
        report = open('./BW_SHFT_res.txt', 'a')
        area_rep = open(AREA_FILE, 'r')
        pwr_rep  = open(PWR_FILE, 'r')

        for line in area_rep:
            if 'Total cell area:' in line:
                area_amt = line.split(':')[1]
                area_amt = "".join(area_amt.split())
                #print area_amt
                break
        for line in pwr_rep:
            if 'Total Dynamic Power' in line:
                pwr_amt1 = line.split('=')[1]
                pwr_amt1 = pwr_amt1.split(' uW')[0]
                #print pwr_amt1
            if 'Cell Leakage Power' in line:
                pwr_amt2 = line.split('=')[1]
                if 'nW' in line:
                    pwr_amt2 = pwr_amt2.split(' nW')[0]
                    small_pwr = 1
                else:
                    pwr_amt2 = pwr_amt2.split(' uW')[0]
                    small_pwr = 0
                #print pwr_amt2

        if(small_pwr==0):
            pwr_amt = float(pwr_amt1) + float(pwr_amt2)
        else:
            pwr_amt = float(pwr_amt1) + float(pwr_amt2)/1000.0
        print pwr_amt

        #report = open('./reports/%d_%d_report.txt' % (i,j),'w')
        
        report.write('BITWIDTH = %d, MAX_SHFT = %d\n'%(i,j) + area_amt + '\n' + str(pwr_amt) + '\n')
        
        area_rep.close()
        pwr_rep.close()
        report.close()

