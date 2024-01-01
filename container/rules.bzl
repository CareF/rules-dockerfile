"""Defines the docker_image rule."""

load("@rules_pkg//pkg:mappings.bzl", "pkg_files")
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")

def _expand_dockerfile_stub_impl(ctx):
    ctx.actions.expand_template(
        template = ctx.file.stub,
        output = ctx.outputs.out,
        substitutions = {
            "{{ARGS}}": ctx.attr.args,
            "{{CONTEXT}}": ctx.file.context.short_path,
            "{{DOCKERFILE}}": "" if ctx.attr.default_dockerfile else ("--file " + ctx.file.dockerfile.short_path),
            "{{TAGS}}": " ".join(["-t " + tag for tag in ctx.attr.image_tags]),
        },
    )

_expand_dockerfile_stub = rule(
    implementation = _expand_dockerfile_stub_impl,
    attrs = {
        "args": attr.string(mandatory = True),
        "context": attr.label(mandatory = True, allow_single_file = True),
        "default_dockerfile": attr.bool(default = True),
        "dockerfile": attr.label(mandatory = True, allow_single_file = True),
        "image_tags": attr.string_list(
            mandatory = True,
            allow_empty = False,
            default = ["latest"],
        ),
        "out": attr.output(mandatory = True),
        "stub": attr.label(
            default = "@rules_dockerfile//stubs:docker_build.sh.tpl",
            allow_single_file = True,
        ),
    },
    output_to_genfiles = True,
)

def docker_image(
        name,
        dockerfile = "Dockerfile",
        label = "",
        image_tags = ["latest"],
        args = [],
        deps = [],
        default_dockerfile = True):
    """Rules to build a docker image from dockerfile.

    Args:
        name: argument description
        dockerfile: filename of the Dockerfile
        label: the label of the docker image, if not specified, it will be "bazel/" + name
        image_tags:
        args:
        deps:
        default_dockerfile: bool, default True. If it is True, the "dockerfile" will be packaged
            into the tar file as /Dockerfile. Otherwise, the "dockerfile" will be remain its
            original path.
    """
    if not label:
        label = "bazel/" + name
    pkg_files(
        name = "_{}_files".format(name),
        srcs = deps,
        strip_prefix = "/",
    )
    pkg_tar(
        name = name + ".tar",
        out = name + ".tar",
        srcs = [":_{}_files".format(name), dockerfile],
        strip_prefix = "." if default_dockerfile else "/",
        remap_paths = {} if default_dockerfile else {
            dockerfile: "Dockerfile",
        },
        include_runfiles = True,
    )
    _expand_dockerfile_stub(
        name = "_{}_shell".format(name),
        out = "build_{}.sh".format(name),
        image_tags = ["{}:{}".format(label, tag) for tag in image_tags],
        args = " ".join(args),
        context = ":{}.tar".format(name),
        dockerfile = dockerfile,
        default_dockerfile = default_dockerfile,
    )
    native.sh_binary(
        name = name,
        srcs = [":_{}_shell".format(name)],
        data = [":{}.tar".format(name)],
    )
