# Implementation Specification: AWS Fuel Price CDN (v1.0)

## 1. Problem Statement
The app currently fetches fuel prices directly from the EIA API, which:
- Has rate limits that could affect high-volume usage
- Requires the API key to be embedded in the app (security concern)
- Has no caching layer for repeated requests
- Could fail during EIA maintenance windows

## 2. Solution: AWS S3 + CloudFront CDN
Host pre-fetched EIA fuel price data on AWS infrastructure with:
- **Private S3 bucket** for storage
- **CloudFront CDN** for secure, fast delivery
- **Lambda function** for daily data refresh
- **Origin Access Control** to keep S3 completely private

## 3. Architecture

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│ EIA API     │ ──── │ Lambda      │ ──── │ S3 (private)│ ──── │ CloudFront  │
│             │      │ (daily 6AM) │      │             │      │ (public)    │
└─────────────┘      └─────────────┘      └─────────────┘      └─────────────┘
                                                                      │
                                                               fuel.pivotallift.com
                                                                      │
                                                               ┌─────────────┐
                                                               │ iOS App     │
                                                               └─────────────┘
```

## 4. Security Model

| Layer | Security Measure |
|-------|------------------|
| S3 Bucket | Private, no public access, OAC only |
| CloudFront | Origin Access Control, AWS Shield |
| Lambda | IAM role with minimal permissions |
| EIA API Key | Stored in AWS Secrets Manager |
| App | No API keys embedded, reads public CDN |

## 5. Data Structure

**S3 Path**: `s3://pivotallift-fuel-prices/diesel-prices.json`

**CloudFront URL**: `https://fuel.pivotallift.com/diesel-prices.json`

```json
{
  "updated": "2026-04-03T06:00:00Z",
  "source": "EIA",
  "expires": "2026-04-04T06:00:00Z",
  "national_average": 3.47,
  "regions": {
    "R1X": { "name": "East Coast", "price": 3.52 },
    "R2X": { "name": "Midwest", "price": 3.31 },
    "R3X": { "name": "Gulf Coast", "price": 3.18 },
    "R4X": { "name": "Rocky Mountain", "price": 3.45 },
    "R5X": { "name": "West Coast", "price": 4.12 },
    "R5XCA": { "name": "California", "price": 4.89 },
    "NUS": { "name": "National", "price": 3.47 }
  }
}
```

## 6. AWS Components

### 6.1 S3 Bucket
- **Name**: `pivotallift-fuel-prices`
- **Region**: `us-east-1`
- **Public Access**: Blocked (all settings)
- **Versioning**: Enabled
- **Lifecycle**: Keep 30 days of versions

### 6.2 CloudFront Distribution
- **Origin**: S3 bucket with OAC
- **Price Class**: Use North America & Europe (cheapest)
- **Default TTL**: 3600 seconds (1 hour)
- **Max TTL**: 86400 seconds (24 hours)
- **Compress**: Yes (gzip)
- **Custom Domain**: `fuel.pivotallift.com` (optional)

### 6.3 Lambda Function
- **Name**: `fetch-eia-fuel-prices`
- **Runtime**: Python 3.12
- **Memory**: 128 MB
- **Timeout**: 30 seconds
- **Trigger**: EventBridge (daily at 6 AM EST)
- **IAM Role**: S3 write, Secrets Manager read

### 6.4 Secrets Manager
- **Secret Name**: `eia-api-key`
- **Value**: `2nBpAfe0Ol29zQ4H0lGRkvmpWfO0ZWMU3UQKdaEY`

## 7. Cost Estimate

| Service | Monthly Cost |
|---------|--------------|
| S3 Storage | $0.02 |
| S3 Requests | $0.01 |
| CloudFront | $0.01 |
| Lambda | $0.00 (free tier) |
| Secrets Manager | $0.40 |
| **Total** | **~$0.50/month** |

## 8. iOS App Changes

Update `FuelPriceService.swift` to:
1. Fetch from CloudFront URL first
2. Fall back to direct EIA API if CDN fails
3. Remove API key from Constants.swift (no longer needed in app)

---

## 9. Implementation Prompt for AI Assistant

> **Instruction:** Follow these steps to implement the AWS fuel price CDN exactly as described.
>
> **Prerequisites provided by user:**
> - AWS Access Key ID
> - AWS Secret Access Key
> - AWS Region (default: us-east-1)
> - Custom domain (optional)
>
> **Step 1: Create S3 Bucket**
> ```bash
> aws s3api create-bucket --bucket pivotallift-fuel-prices --region us-east-1
> aws s3api put-public-access-block --bucket pivotallift-fuel-prices \
>   --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
> aws s3api put-bucket-versioning --bucket pivotallift-fuel-prices --versioning-configuration Status=Enabled
> ```
>
> **Step 2: Store EIA API Key in Secrets Manager**
> ```bash
> aws secretsmanager create-secret --name eia-api-key \
>   --secret-string "2nBpAfe0Ol29zQ4H0lGRkvmpWfO0ZWMU3UQKdaEY"
> ```
>
> **Step 3: Create Lambda Function**
> Create `lambda_function.py` with EIA fetch logic, deploy to AWS Lambda.
>
> **Step 4: Create CloudFront Distribution**
> Create distribution with OAC pointing to S3 bucket.
>
> **Step 5: Set Up EventBridge Rule**
> Schedule Lambda to run daily at 6 AM EST.
>
> **Step 6: Update iOS App**
> Modify `FuelPriceService.swift` to fetch from CloudFront URL.
>
> **Step 7: Test End-to-End**
> Trigger Lambda manually, verify JSON in S3, fetch from CloudFront URL.

---

## 10. Success Metrics

- **Uptime**: 99.9% (CloudFront SLA)
- **Latency**: <50ms from edge locations
- **Cost**: <$1/month
- **Security**: No API keys in app binary
- **Freshness**: Data updated daily by 6:15 AM EST

## 11. Rollback Plan

If issues occur:
1. iOS app falls back to direct EIA API automatically
2. Can disable CloudFront and revert to embedded API key
3. S3 versioning allows restoring previous data files
