# Documentation

## Jazzy
Documentation generated with [Jazzy](https://github.com/realm/jazzy) application.
To prepare or update documenation

### Generate source structure

```
sourcekitten doc --spm-module CAPI > Documentation/MNIST.json
```

### Generate documentation
```
jazzy --config Documentation/MNIST.yaml
```
### Script
If you want to generate all documentation call script:
```
Documentation/generate.sh
```
