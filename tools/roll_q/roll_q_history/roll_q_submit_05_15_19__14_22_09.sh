#!/bin/bash
sbatch ./jobs/median__reduced__100_tests__0_90000_dilution.sb
sbatch ./jobs/median__reduced__100_tests__0_95000_dilution.sb
sbatch ./jobs/median__reduced__50_tests__0_90000_dilution.sb
sbatch ./jobs/median__reduced__50_tests__0_95000_dilution.sb
sbatch ./jobs/median__reduced__25_tests__0_90000_dilution.sb
sbatch ./jobs/median__reduced__25_tests__0_95000_dilution.sb
sbatch ./jobs/median__reduced__10_tests__0_90000_dilution.sb
sbatch ./jobs/median__reduced__10_tests__0_95000_dilution.sb
sbatch ./jobs/median__reduced__5_tests__0_90000_dilution.sb
sbatch ./jobs/median__reduced__5_tests__0_95000_dilution.sb
