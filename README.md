# rules_dockerfile (WIP)

Rules for using Dockerfile for building container images in Bazel projects.

This is intended for people who still want to stick to Dockerfile
(v.s. [rules_docker](https://github.com/bazelbuild/rules_docker) or
[rules_oci](https://github.com/bazel-contrib/rules_oci)) for constructing container images.

Concept: `docker_image`

## Example

TODO

```bash
bazel run //hello:hello_world_image.build
```

This shall build a docker image and register it to your local machine with name `hello/hello_world`
and tag `latest`.

We intentionally do not support `bazel build` a `tar` file for a image as a best respect to the
[hermeticity](#hermeticity) Bazel philosophy.

Alternatively if you want to run the image,

```bash
bazel run //hello:hello_world_image
```

## Integrating with kaniko

[kaniko](https://github.com/GoogleContainerTools/kaniko) is widely used for automatic building and
publishing images, especially in CI/CD pipelines.

We provide a `tar.gz` file result as an intermediate Bazel target to use as a `--context` input
with kaniko to integrate the `docker_image` with kaniko.

See the [kaniko document](https://github.com/GoogleContainerTools/kaniko#kaniko-build-contexts)
for more detail.

## Hermeticity

The Bazel philosophy include building with [hermeticity](https://bazel.build/basics/hermeticity).
A image described by a Dockerfile is usually not reproducible or deterministic. See
[bazelbuild/rules_docker#173](https://github.com/bazelbuild/rules_docker/issues/173) and
[Building deterministic Docker images with Bazel](https://blog.bazel.build/2015/07/28/docker_build.html)
for detailed discussion. This is likely the reason why the official and some best organizations
prefer not to use Dockerfile for building images. However Dockerfile is yet still the de-facto
standard for describing how to build images, and building an image is, in most cases, the last step
of building cloud-based apps, so this non-bazel-style compromise is what I would stand with.

## Version support

This project is developed and tested under Bazel 5.4.0.
