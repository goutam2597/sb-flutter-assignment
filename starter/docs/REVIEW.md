## Code Review & Strongest Findings

### 1. Live API Credentials Are Hardcoded in the App

**Severity:** Critical

#### Impact

Anyone who gets access to the APK, IPA, build files, or source code could inspect the application and extract the live API credentials.

They may then be able to:

* Send SMS messages using the company’s billing account
* Generate unauthorized SMS charges
* Access billing information
* Access or interact with other tenants, depending on the API key permissions

#### Location

```dart
const String kApiKey = 'fw_live_…';
```

The key is declared on line 9 and used around lines 48, 74, and 127.

#### What Is Wrong

The production API key is stored directly inside the Flutter application and sent with API requests as a bearer token.

Mobile applications can be inspected and reverse-engineered. Therefore, any secret stored inside the application should be considered accessible.

Code obfuscation may make the key harder to find, but it does not securely protect it.

The `fw_live_` prefix also indicates that this is a live production credential rather than a test key.

#### What I Need to Do

* Need to revoke and rotate the exposed API key immediately
* Need to remove all permanent API keys and provider credentials from Flutter
* Need to authenticate users through a trusted backend
* Need to issue short-lived access tokens limited to the authenticated user and tenant
* Need to keep all permanent secrets on the server

The API contract already supports short-lived tokens through:

```text
POST /auth/refresh
```

---

### 2. Sensitive Information Is Sent Through Plain HTTP

**Severity:** Critical

#### Impact

Anyone able to inspect the network connection may be able to read or modify:

* Authentication tokens
* Recipient phone numbers
* SMS message content
* OTP codes
* Billing and cost information

#### Location

```dart
const String kApiBase = 'http://api.formwork.internal';
```

The base URL is declared on line 8 and used around lines 46–49, 71–78, and 125–128.

#### What Is Wrong

The application uses `http://` instead of `https://`.

This means sensitive information may be transmitted without encryption and could be intercepted or modified while travelling between the application and the server.

#### What I Need to Do

* Need to require HTTPS for every API endpoint
* Need to install and maintain a valid SSL certificate
* Need to disable cleartext HTTP traffic on Android
* Need to enforce App Transport Security on iOS
* Need to validate that all API URLs use the HTTPS scheme

---

### 3. Tenant ID Is Declared but Never Sent

**Severity:** Critical

#### Impact

Requests may be processed under the wrong tenant, which could cause:

* Incorrect tenant billing
* Incorrect SMS provider configuration
* One tenant seeing another tenant’s information
* Cross-tenant data leakage

#### Location

```dart
const String kTenantId = '9f1c2d3e-4a5b-6c7d-8e9f-0a1b2c3d4e5f';
```

The tenant ID is declared on line 10 but is never included in the API requests.

#### What Is Wrong

The API contract requires the following header on every request:

```text
X-Tenant-Id
```

However, the application only sends the authorization token and does not send the tenant ID.

This means the application does not properly follow the multi-tenant API contract.

#### What I Need to Do

* Need to validate the tenant on the backend using the authenticated token
* Need to include `X-Tenant-Id` on every tenant-specific request
* Need to use a shared API client or interceptor to attach the required headers
* Need to clear cached data and application state when switching tenants

---

### 4. Money Is Stored and Calculated Using `double`

**Severity:** Critical

#### Impact

Using floating-point numbers for financial calculations can create small rounding errors.

Across thousands of SMS messages, these errors may lead to:

* Incorrect cost totals
* Incorrect customer balances
* Incorrect invoices
* Billing disagreements

#### Location

Money is handled as `double` around lines 51, 82–88, and 140.

#### What Is Wrong

The API contract returns monetary values as decimal strings, for example:

```json
{
  "cost": "0.1500",
  "totalCost": "8.2500"
}
```

The application attempts to use these values as `double`.

Floating-point numbers cannot represent many decimal values exactly, which makes them unsuitable for precise financial calculations.

#### What I Need to Do

* Need to use a decimal-number library
* Alternatively, need to store money as integer minor units
* Need to parse the decimal strings returned by the backend
* Need to perform all calculations using a precise money type
* Need to format the values only when displaying them

---

### 5. The App Calculates SMS Pricing Locally

**Severity:** High

#### Impact

The amount displayed in the app may not match the real amount charged by the backend or SMS provider.

This can result in:

* Misleading cost estimates
* Customer billing complaints
* Different totals between the app and invoices

#### Location

The local provider pricing is defined in:

```dart
double rateFor(String provider) {
  if (provider == 'TWILIO') return 0.075;
  if (provider == 'VONAGE') return 0.065;
  if (provider == 'AWS_SNS') return 0.046;
  return 0.07;
}
```

The final cost is calculated locally around line 86.

#### What Is Wrong

The application contains hardcoded prices for different SMS providers.

However, the SMS send response already returns the official:

* Cost
* Currency
* Segment count

The backend should remain the trusted source for billing information.

#### What I Need to Do

* Need to remove the `rateFor()` method
* Need to remove all hardcoded SMS prices from Flutter
* Need to use the `cost` returned by the backend
* Need to use the `currency` returned by the backend
* Need to use the `segmentCount` returned by the backend

---

### 6. Every Message Is Treated as One SMS Segment

**Severity:** High

#### Impact

Long messages and messages containing Unicode characters may be divided into multiple billable SMS segments.

The application may show the price of one segment while the user is charged for several.

#### Location

```dart
final segments = 1;
```

This is declared around line 82.

#### What Is Wrong

The application assumes every SMS contains exactly one segment.

In reality, the number of segments depends on:

* Message length
* Character encoding
* Unicode characters
* Concatenated SMS rules

#### What I Need to Do

* Need to use the `segmentCount` returned by the backend after sending the message
* Need to clearly mark any locally calculated segment count as an estimate before sending

---

### 7. Currency Is Always Displayed as Euros

**Severity:** High

#### Impact

Amounts returned in currencies such as USD, GBP, or BDT may incorrectly appear as euros.

The application may also add values from different currencies together, creating an incorrect total.

#### Location

Several parts of the UI display money using:

```dart
€
```

This appears around lines 53–56, 88, 122, and 141.

#### What Is Wrong

The API returns a currency code, but the application ignores it and always displays the euro symbol.

The application also appears to calculate a combined total without checking whether all values use the same currency.

#### What I Need to Do

* Need to store the currency code with every amount
* Need to display the currency returned by the backend
* Need to format money using the correct currency
* Need to group totals by currency
* Need to avoid adding different currencies together unless a proper conversion is performed

---

### 8. Valid API Responses May Crash the Cost Screen

**Severity:** High

#### Impact

The billing or cost screen may crash or remain unusable even when the backend returns a valid response.

#### Location

The application directly casts `totalCost` as a `double` around lines 51 and 141.

#### What Is Wrong

The API contract returns values such as:

```json
{
  "totalCost": "8.2500"
}
```

This value is a string.

A string cannot be directly cast using:

```dart
value as double
```

This causes a runtime error.

The same problem may happen if the backend returns a whole number as an integer.

#### What I Need to Do

* Need to create typed response models
* Need to parse decimal strings safely
* Need to validate every response field
* Need to handle invalid rows without crashing the entire screen
* Need to display a controlled error message when data is malformed

---

### 9. Failed Requests Can Leave the App Loading Forever

**Severity:** High

#### Impact

The screen may remain stuck on a loading spinner when:

* The user is offline
* The request times out
* DNS resolution fails
* The server returns an error
* The API returns invalid JSON
* The authentication token expires
* The user is rate-limited

#### Location

The issue exists inside the `loadCosts()` method around lines 44–61.

#### What Is Wrong

The method performs network and parsing operations without proper:

```dart
try
catch
finally
```

If an exception occurs before `loading` is changed back to `false`, the loading indicator never stops.

#### What I Need to Do

* Need to wrap the request in `try/catch/finally`
* Need to always stop the loading state inside `finally`
* Need to add a request timeout
* Need to check the HTTP response status
* Need to show a clear error message
* Need to provide a retry button
* Need to handle authentication, server, rate-limit, and connectivity errors separately

---

### 10. The App May Show False Success and Invalid Recipient Information

**Severity:** High

#### Impact

The user may be told that an SMS was sent even when it was:

* Rejected
* Rate-limited
* Only queued
* Not delivered
* Failed by the SMS provider

The billing screen may also attempt to show recipient information that the API does not return.

#### Location

The SMS send flow is around lines 71–91.

The recipient is displayed around line 140.

#### What Is Wrong

The application does not properly check the HTTP status before displaying:

```dart
Sent via $provider
```

A `202 Accepted` response only means that the request was accepted or queued. It does not confirm that the SMS was delivered.

The API contract describes delivery as an asynchronous process:

```text
ACCEPTED → SENT → DELIVERED
                  ↘ FAILED
```

The application also reads:

```dart
rows[i]['recipient']
```

However, the cost breakdown endpoint does not return a recipient field.

#### What I Need to Do

* Need to check the HTTP status before parsing the response
* Need to show `Accepted` or `Queued` for a `202` response
* Need to track the actual delivery status separately
* Need to handle `400`, `401`, `403`, `429`, and server errors properly
* Need to respect the `Retry-After` header for rate-limited requests
* Need to remove the recipient from the cost breakdown screen
* Need to show only masked recipient data from the correct message-history endpoint

---

## Most Serious Real-World Risks

The two most serious findings are:

### Exposed Production Credential

The hardcoded live API key could allow unauthorized users to send SMS messages, create billing charges, and possibly access other tenants.

### Incorrect Financial Calculations

Using `double` for monetary values may create inaccurate cost totals and incorrect invoices.

---

## Additional Issues Found

The code also contains several other important problems:

* Global static state may retain information when switching tenants
* Phone numbers and SMS content may be printed in logs
* No idempotency protection exists for duplicate billable sends
* The send button may allow multiple requests at the same time
* `setState()` or `context` may be used after an asynchronous operation without checking `mounted`
* Network requests may run again when the widget rebuilds
* Error messages may expose internal server information
* API responses are not represented using proper typed models

---