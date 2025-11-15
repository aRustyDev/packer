# Adding Vars

1. Add the variable to `vars.pkr.hcl`:

```hcl
variable "foo" {
  type        = string
  description = "[is Optional?] Put a descriptive string here to explain the context."
  default     = "SomeSaneDefault"
  # validation logic just tests format/logic/type of the variable
  # ex: if a var needs a map(string), then an arr(bool) would fail validation
  # hint: AI really helps here
  validation {
    condition     = length(var.foo) > 0
    error_message = "foo must not be empty"
  }
}
```

2. Add the variable to `.templates/pkrvars.mustache`

```mustache
{{! Mustache Comments start w/ '!' }}
foo={{var.key.path}}
```

3. Make sure the Config.yaml will have the value set (either manually or automatically)

- If manually, add it to `.templates/config.default.mustache`
- If automatically, update the relevant justfile recipe to generate the value
  - See 'recipe' for example
