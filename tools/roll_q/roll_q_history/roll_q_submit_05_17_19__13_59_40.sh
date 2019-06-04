#!/bin/bash
sbatch ./jobs/grade__downsampled__25_tests__0_00000_dilution.sb
sbatch ./jobs/grade__downsampled__25_tests__0_50000_dilution.sb
sbatch ./jobs/grade__downsampled__25_tests__0_75000_dilution.sb
sbatch ./jobs/grade__downsampled__25_tests__0_90000_dilution.sb
sbatch ./jobs/grade__downsampled__25_tests__0_95000_dilution.sb
sbatch ./jobs/grade__downsampled__5_tests__0_00000_dilution.sb
sbatch ./jobs/grade__downsampled__5_tests__0_50000_dilution.sb
sbatch ./jobs/grade__downsampled__5_tests__0_75000_dilution.sb
sbatch ./jobs/grade__downsampled__5_tests__0_90000_dilution.sb
sbatch ./jobs/grade__downsampled__5_tests__0_95000_dilution.sb
