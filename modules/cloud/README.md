# Cloud Misconfiguration Modules

Scripts in this directory target cloud platform weaknesses:
- AWS: S3 bucket enumeration, IAM privilege escalation, Lambda abuse
- Azure: Storage account enumeration, service principal abuse
- GCP: GCS bucket enumeration, metadata server abuse
- Cross-cloud credential harvesting

## Naming Convention

`<provider>_<technique>.py|sh`

Example: `aws_s3_enum.py`, `azure_sp_enum.sh`, `gcp_metadata.py`

## Usage

```bash
vex cloud <script> [args...]
vex cloud <script> -ai [args...]
```
