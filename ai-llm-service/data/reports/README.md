# Reports Directory

This folder contains auto-generated correction reports and test results.

## Files Generated Here:
- `correction_report_YYYYMMDD_HHMMSS.json` - Detailed correction analysis
- `test_result_YYYYMMDD_HHMMSS.json` - Test outputs

## Note:
These files are temporary and regenerated each time you run the tools.
They are gitignored to keep the repository clean.

## View Reports:
```bash
# List all reports
ls -lth reports/

# View latest report
cat reports/correction_report_*.json | jq

# Count corrections in latest report
cat reports/correction_report_*.json | jq '.corrections_made.total_corrections'
```
