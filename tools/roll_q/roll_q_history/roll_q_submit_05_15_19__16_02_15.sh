#!/bin/bash
sbatch ./jobs/grade__cohort__5_tests__0_95000_dilution.sb
sbatch ./jobs/grade__reduced__100_tests__0_00000_dilution.sb
sbatch ./jobs/grade__reduced__100_tests__0_50000_dilution.sb
sbatch ./jobs/grade__reduced__100_tests__0_75000_dilution.sb
sbatch ./jobs/grade__reduced__100_tests__0_90000_dilution.sb
sbatch ./jobs/grade__reduced__100_tests__0_95000_dilution.sb
sbatch ./jobs/grade__reduced__50_tests__0_00000_dilution.sb
