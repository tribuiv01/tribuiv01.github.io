GCP: https://cloud.google.com/docs/terraform/install-configure-terraform

- Create project
- Enable billing
- Enable services

Next steps

```
gcloud init
gcloud auth application-default login
```

Naming convention:

```
Organization: techviet.com

Folders:
engineering
finance
marketing
shared-services

Projects:
techviet-prod-eng-webapp-001
techviet-dev-eng-webapp-001
techviet-prod-finance-erp-001
techviet-shared-networking-001

Resources:
VM: p-webapp-api-us-central1-001
Storage: techviet-marketing-assets-us
Database: p-erp-postgres-us-central1
```