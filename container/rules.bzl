"""Defines the docker_image rule."""

load("@rules_pkg//pkg:mappings.bzl", "pkg_attributes", "pkg_files")
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")

def _expand_dockerfile_stub_impl(ctx):
    dockerfile_path = "Dockerfile" if ctx.attr.default_dockerfile else ctx.file.dockerfile.short_path
    script = ctx.actions.declare_file(ctx.attr.name)
    runfiles = ctx.runfiles(files = [ctx.file.context])
    ctx.actions.expand_template(
        template = ctx.file.stub,
        output = script,
        substitutions = {
            "{{ARGS}}": ctx.attr.image_args,
            "{{CONTEXT}}": ctx.file.context.short_path,
            "{{DOCKERFILE}}": dockerfile_path,
            "{{TAGS}}": " ".join(["-t " + tag for tag in ctx.attr.image_tags]),
        },
    )
    return DefaultInfo(runfiles = runfiles, executable = script)

_expand_dockerfile_stub = rule(
    implementation = _expand_dockerfile_stub_impl,
    attrs = {
        "context": attr.label(mandatory = True, allow_single_file = True),
        "default_dockerfile": attr.bool(default = True),
        "dockerfile": attr.label(mandatory = True, allow_single_file = True),
        "image_args": attr.string(mandatory = True),
        "image_tags": attr.string_list(
            mandatory = True,
            allow_empty = False,
            default = ["latest"],
        ),
        "stub": attr.label(
            default = "@rules_dockerfile//stubs:docker_build.sh.tpl",
            allow_single_file = True,
        ),
    },
    output_to_genfiles = True,
    executable = True,
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
        attributes = pkg_attributes(
            # Override the default 644 permissions since there may be executables
            # 0555 is the default permission for files directly loaded in pkg_tar
            mode = "0555",
        ),
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
        name = name,
        image_tags = ["{}:{}".format(label, tag) for tag in image_tags],
        image_args = " ".join(args),
        context = ":{}.tar".format(name),
        dockerfile = dockerfile,
        default_dockerfile = default_dockerfile,
    )
