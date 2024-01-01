# rules_dockerfile (WIP)

Rules for using Dockerfile for building container images in Bazel projects.

This is intended for people who still want to stick to Dockerfile
(v.s. [rules_docker](https://github.com/bazelbuild/rules_docker) or
[rules_oci](https://github.com/bazel-contrib/rules_oci)) for constructing container images.

This bazel package provides a macro called `docker_image` to support running docker build/run/push in a bazel repo.

## Rule `docker_image` arguments

- `dockerfile`: str, default `"Dockerfile"`, the path to the Dockerfile used for the image.
- `label`: str, default `"bazel/<name>"`, the label of the image.
- `image_tags`: list, default `["latest"]`, the tags of the image. They combines with `label`.
- `args`: list, default `[]`, the extra arguments to pass to the `docker build` command.
- `deps`: list, default `[]`, the dependencies of the image. All files needed to build the image should be listed here.
- `default_dockerfile`: bool, default `True`. Whether to rename the `dockerfile` to `/Dockerfile` in the built context tarball.

## Usage:

In your `WORKSPACE` file, add the following lines:

```starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "rules_dockerfile",
    urls = [
        "https://github.com/CareF/rules-dockerfile/archive/refs/tags/v0.0.6.tar.gz",  # update the tag accordingly
    ],
    sha256 = "<fill in the sha256 accordingly>",
)

load("@rules_dockerfile//deps:deps.bzl", "rules_dockerfile_dependencies")

rules_dockerfile_dependencies()  # or alternatively, adding rules_pkg and bazel_skylib manually

load("@rules_pkg//pkg:deps.bzl", "rules_pkg_dependencies")

rules_pkg_dependencies()

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()
```

In your `BUILD` file, add docker image target like:

```starlark
load("@rules_dockerfile//container:rules.bzl", "docker_image")

docker_image(
    name = "hello",
    image_tags = [
        "v1.0.0",
        "latest",
    ],
    label = "example/hello_world",
)
```

## Example

To build a image in local machine, run the following command.

```bash
bazel run //examples/hello_world:hello
```

This shall build a docker image and register it to your local machine with name `local/hello_world`
and tag `latest` and `v1.0.0`.

We intentionally do not support `bazel build` an image `tar` file as a best respect to the
[hermeticity](#hermeticity) Bazel philosophy.

Alternatively if you want to run the image,

```bash
bazel run //examples/hello_world:hello.RUN
```

To push the image,

```bash
bazel run //examples/hello_world:hello.PUSH
```

See [examples](examples/) for more details.

## Integrating with kaniko

[kaniko](https://github.com/GoogleContainerTools/kaniko) is widely used for automatic building and
publishing images, especially in CI/CD pipelines.

We provide a `tar.gz` context file as an intermediate Bazel target to use for the `--context` input
with kaniko. For using it as CI jobs

### GitHub-Action

TBD

### GitLab-ci

TBD

```yaml
# define a job for building the tarball artifacts
build-tar:
  stage: build
  tags:
    - runner-${ARCH}
  image:
    name: ${BAZEL_ENV_IMAGE}
    entrypoint: [""]
  script:
    - bazel build //path/to/target:image_tar
  artifact:
    path: bazel-out/

build-container:
  stage: publish
  tags:
    # run each build on a suitable, pre-configured runner (must match the target architecture)
    - runner-${ARCH}
  image:
    name: gcr.io/kaniko-project/executor:debug
    entrypoint: [""]
  script:
    - >-
      /kaniko/executor
      --context "${CI_PROJECT_DIR}"
      --dockerfile "${CI_PROJECT_DIR}/Dockerfile"
      # push the image to the GitLab container registry, add the current arch as tag.
      --destination "${CI_REGISTRY_IMAGE}:${ARCH}"
```

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

This project is developed and tested under Bazel 5.4.1.
