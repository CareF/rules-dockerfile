load("@rules_dockerfile//container:rules.bzl", "docker_image")

docker_image(
    name = "foo",
    label = "local/foo",
    deps = [
        "//examples/resources:foo.txt",
    ],
)
