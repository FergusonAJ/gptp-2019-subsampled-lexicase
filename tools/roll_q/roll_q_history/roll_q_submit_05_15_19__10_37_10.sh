#!/bin/bash
sbatch ./jobs/median__downsampled__100_tests__0_90000_dilution.sb
sbatch ./jobs/median__downsampled__100_tests__0_95000_dilution.sb
sbatch ./jobs/median__downsampled__50_tests__0_90000_dilution.sb
sbatch ./jobs/median__downsampled__50_tests__0_95000_dilution.sb
sbatch ./jobs/median__downsampled__25_tests__0_90000_dilution.sb
sbatch ./jobs/median__downsampled__25_tests__0_95000_dilution.sb
sbatch ./jobs/median__downsampled__10_tests__0_90000_dilution.sb
sbatch ./jobs/median__downsampled__10_tests__0_95000_dilution.sb
sbatch ./jobs/median__downsampled__5_tests__0_90000_dilution.sb
sbatch ./jobs/median__downsampled__5_tests__0_95000_dilution.sb
