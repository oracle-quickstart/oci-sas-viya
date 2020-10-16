#!/bin/sh

trap cleanup HUP INT QUIT ABRT TERM EXIT

generate_dockerfile()
{
    cat <<EOF
FROM alpine:latest

RUN mkdir -p /payload/content
COPY ["$QKB_SOURCE", "/payload/content/qkb.qarc"]
RUN sha1sum /payload/content/qkb.qarc | cut -d' ' -f1 > /payload/check.sha1
RUN echo "$QKB_NAME" > /payload/name
EOF
}

info()
{
    [ $QUIET -ne 1 ] && echo $*
}

verbose()
{
    [ $QUIET -ne 1 -a $VERBOSE -eq 1 ] && echo $*
}

cleanup()
{
    [ -n "$QKB_STAGE_DIR" ] && rm -rf "$QKB_STAGE_DIR"
}

usage()
{
    cat <<EOF
Usage: $0 [OPTIONS] NAME PATH REPO[:TAG]

Generates a Docker container that will deploy a QKB QARC file into SAS Viya.

Mandatory arguments:
    NAME - The name by which the QKB will be known.
    PATH - The local path in which to find the source QARC file.
    TAG  - The docker repo and optional tag to apply to generated container.

Optional arguments:
    --dockerfile-only  Only generate the Dockerfile and output to stdout
    --quiet            Don't output any status messages
    --verbose          Output as much info as possible

EOF

    exit 1
}

DOCKERFILE_ONLY=0
VERBOSE=0
QUIET=0

# Parse the optional args.
while [ $# -gt 3 ] ; do
    case $1 in
        --dockerfile-only)
            DOCKERFILE_ONLY=1
            ;;
        --quiet)
            QUIET=1
            ;;
        --verbose)
            VERBOSE=1
            ;;
        *)
            usage
            ;;
    esac
    shift
done

# Parse the mandatory args.
[ $# -ne 3 ] && usage
QKB_NAME="$1"
QKB_PATH="$2"
QKB_TAG="$3"
QKB_SOURCE="`basename $QKB_PATH`"

# Check for Docker.
DOCKER="`which docker 2> /dev/null`"
if [ -z "$DOCKER" ] ; then
    echo "This program requires Docker, but it could not be found in current PATH."
    exit 1
fi

# Validate path.
if [ -d "$QKB_PATH" ] ; then
    echo "The path '$QKB_PATH' refers to a directory; must be a file."
    exit 1
elif [ ! -f "$QKB_PATH" ] ; then
    echo "The path '$QKB_PATH' is invalid."
    exit 1
fi

# Just output the dockerfile if that's all that's requested.
if [ $DOCKERFILE_ONLY -eq 1 ] ; then
    generate_dockerfile
    exit 1
fi

# Copy the source file into the stage dir.
info "Setting up staging area..."
QKB_STAGE_DIR="`mktemp -d`"
if ! cp "$QKB_PATH" "$QKB_STAGE_DIR" ; then
    echo "Error occurred while copying files."
    exit 1
fi

# Generate dockerfile.
info "Generating Dockerfile..."
generate_dockerfile > "$QKB_STAGE_DIR/Dockerfile"
[ $VERBOSE -eq 1 ] && generate_dockerfile

# Run docker.
info "Running docker..."
OUT_REDIR=/dev/null
[ $QUIET -eq 0 -a $VERBOSE -ne 0 ] && OUT_REDIR=/dev/stdout
cd "$QKB_STAGE_DIR"
"$DOCKER" build -t "$QKB_TAG" . > $OUT_REDIR
if [ $? -ne 0 ] ; then
    echo "Error occurred while running Docker."
    exit 1
fi

info "Docker container generated successfully."
info
if [ $QUIET -ne 1 ] ; then
    "$DOCKER" images "$QKB_TAG"
fi

# Clean up.
cleanup

