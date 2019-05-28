#!/bin/bash
sbatch ./jobs/median__cohort__100_tests__0_90000_dilution.sb
sbatch ./jobs/median__cohort__100_tests__0_95000_dilution.sb
sbatch ./jobs/median__cohort__50_tests__0_90000_dilution.sb
sbatch ./jobs/median__cohort__50_tests__0_95000_dilution.sb
sbatch ./jobs/median__cohort__25_tests__0_90000_dilution.sb
sbatch ./jobs/median__cohort__25_tests__0_95000_dilution.sb
sbatch ./jobs/median__cohort__10_tests__0_90000_dilution.sb
sbatch ./jobs/median__cohort__10_tests__0_95000_dilution.sb
sbatch ./jobs/median__cohort__5_tests__0_90000_dilution.sb
sbatch ./jobs/median__cohort__5_tests__0_95000_dilution.sb
