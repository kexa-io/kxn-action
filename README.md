# kxn-action

GitHub Action for [kxn](https://github.com/kexa-io/kxn) — scan infrastructure against compliance rules (CIS, PCI-DSS, ISO27001).

## Usage

### Scan with pre-gathered data

```yaml
- uses: kexa-io/kxn-action@v1
  with:
    rules: ./rules
    resource-file: gathered-resources.json
```

### Gather + Scan (Kubernetes)

```yaml
- uses: kexa-io/kxn-action@v1
  with:
    rules: ./rules
    provider: kubernetes
    provider-config: '{"K8S_API_URL":"${{ secrets.K8S_API }}", "K8S_TOKEN":"${{ secrets.K8S_TOKEN }}"}'
    tags: security,cis
```

### Scan with inline resource data

```yaml
- uses: kexa-io/kxn-action@v1
  with:
    rules: ./rules
    resource: '{"sshd_config":{"permitrootlogin":"no","protocol":"2"}}'
```

### Non-blocking scan (warn but don't fail)

```yaml
- uses: kexa-io/kxn-action@v1
  with:
    rules: ./rules
    resource-file: data.json
    fail-on-violations: 'false'
```

## Inputs

| Input | Description | Default |
|-------|-------------|---------|
| `version` | kxn version | `latest` |
| `rules` | Rules directory/file | `./rules` |
| `resource` | Inline JSON resource data | |
| `resource-file` | Path to JSON resource file | |
| `config` | kxn.toml config file | |
| `provider` | Provider for gathering | |
| `provider-config` | Provider config JSON | `{}` |
| `resource-type` | Resource type to gather | `all` |
| `output` | Output format: text, json, sarif | `sarif` |
| `sarif-file` | SARIF output path | `kxn-results.sarif` |
| `upload-sarif` | Upload to GitHub Security tab | `true` |
| `include` | Include rules glob | |
| `exclude` | Exclude rules glob | |
| `tags` | Filter by tags (comma-separated) | |
| `min-level` | Minimum severity (0-3) | |
| `fail-on-violations` | Fail on violations | `true` |

## Outputs

| Output | Description |
|--------|-------------|
| `total` | Total rules evaluated |
| `passed` | Rules passed |
| `failed` | Rules failed |
| `sarif-file` | SARIF file path |

## SARIF + GitHub Security

By default, results are uploaded to the **Security > Code scanning** tab. Violations appear as alerts with CIS/PCI-DSS compliance tags.

## License

Apache-2.0
