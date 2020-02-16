# rust-musl-builder

Tweaked variant of  https://github.com/emk/rust-musl-builder that can be used inside github actions like this:

```
name: Build
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - name: Build
      uses: docker://untoldwind/rust-musl-builder:latest
      with:
        args: cargo build --release
```
