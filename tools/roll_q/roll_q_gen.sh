#!/bin/bash
TIMESTAMP=`date +%m_%d_%y__%H_%M_%S`
mv ./tools/roll_q/roll_q_idx.txt ./tools/roll_q/roll_q_history/roll_q_idx_${TIMESTAMP}.txt
mv ./tools/roll_q/roll_q_job_array.txt ./tools/roll_q/roll_q_history/roll_q_job_array_${TIMESTAMP}.txt
python3 ./tools/gen_roll_q_array.py
