#!/bin/bash
NUM_JOBS_IN_QUEUE=`sq | grep -P "\d+\s+Jobs\s+in\s+the\s+queue" -o | grep -P "\d+" -o`
TIMESTAMP=`date +%m_%d_%y__%H_%M_%S`
echo "$NUM_JOBS_IN_QUEUE jobs currently in queue"
python3 ./tools/roll_q/roll_q.py $NUM_JOBS_IN_QUEUE
chmod a+x ./tools/roll_q/roll_q_submit.sh
echo ""
echo "Here's the script:"
cat ./tools/roll_q/roll_q_submit.sh
./tools/roll_q/roll_q_submit.sh
mv ./tools/roll_q/roll_q_submit.sh ./tools/roll_q/roll_q_history/roll_q_submit_${TIMESTAMP}.sh
echo "Script saved at \"./tools/roll_q/roll_q_history/roll_q_submit_${TIMESTAMP}.sh\""
