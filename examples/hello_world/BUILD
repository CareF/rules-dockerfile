load("@rules_dockerfile//container:rules.bzl", "docker_image")

docker_image(
    name = "hello",
    image_tags = [
        "v1.0.0",
        "latest",
    ],
    label = "example/hello_world",
    # default_dockerfile = False,
)
