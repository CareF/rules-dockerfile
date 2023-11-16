load("@rules_duckerfile//container:rules.bzl", "docker_image")

docker_image(
    name = "hello",
    image_tags = [
        "v1.0.0",
        "latest",
    ],
    label = "local/hello_world",
    # default_dockerfile = False,
)
