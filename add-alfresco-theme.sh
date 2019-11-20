#!/bin/bash -e

log_info() {
    echo "info::: $1"
}

log_error() {
    echo "error::: $1"
    exit 1
}

print_usage() {
    cat <<EOF
    The required environment variables are not set:
    - THEME_VERSION
    OR
    - THEME_GIT_REPO
    - THEME_GIT_BRANCH ('master' will be used if not set)

    Example-1, adding alfresco-theme from a branch:
        export THEME_GIT_REPO=alfresco-keycloak-theme
        export THEME_GIT_BRANCH=test-branch
        sh add-alfresco-theme.sh

    Example-2, adding alfresco-theme from a released version:
        export THEME_VERSION=0.1
        sh add-alfresco-theme.sh
EOF
    exit 1
}

if [ -z "$THEME_VERSION" ] && [ -z "$THEME_GIT_REPO" ]; then
    print_usage
fi

WORK_DIR="$PWD"
TMP=$(mktemp -d)
VERSION="$KEYCLOAK_VERSION"
if [ -z "$VERSION" ]; then
    log_info "KEYCLOAK_VERSION environment variable is not set. Get the version from the project pom.xml"
    VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
fi
log_info "Using keycloak version: $VERSION"

KEYCLOAK_DIR="$WORK_DIR/distribution/server-dist/target"
KEYCLOAK_DIST="$KEYCLOAK_DIR/keycloak-$VERSION.zip"
if [ ! -f "$KEYCLOAK_DIST" ]; then
    log_error "$KEYCLOAK_DIST does not exist."
fi

cd $TMP
if [ -n "$THEME_GIT_REPO" ]; then
    if [ -z "$THEME_GIT_BRANCH" ]; then
        THEME_GIT_BRANCH='master'
    fi

    # Clone repository
    log_info "Clone branch '$THEME_GIT_BRANCH' from repo: $THEME_GIT_REPO"
    git clone --depth 1 https://github.com/Alfresco/$THEME_GIT_REPO.git -b $THEME_GIT_BRANCH alfresco-keycloak-theme

    mkdir alfresco
    log_info "Copy Alfresco theme..."
    cp -rf alfresco-keycloak-theme/theme/* alfresco/
else
    THEME_DIST="https://github.com/Alfresco/alfresco-keycloak-theme/releases/download/$THEME_VERSION/alfresco-keycloak-theme-$THEME_VERSION.zip"
    log_info "Download Alfresco theme from: $THEME_DIST"

    curl -sSLO "$THEME_DIST"
    if ! unzip -oq alfresco-keycloak-theme-$THEME_VERSION.zip; then
        log_error "Couldn't unzip alfresco-keycloak-theme."
    fi
fi

# unzip keycloak in the current directory (i.e. TMP)
log_info "Unzipping 'keycloak-$VERSION'..."
unzip -oq $KEYCLOAK_DIST -d .
rm $KEYCLOAK_DIST

log_info "Add Alfresco theme into keycloak-$VERSION/themes"
cp -rf alfresco keycloak-$VERSION/themes/
log_info "Zipping 'keycloak-$VERSION'..."
zip -rq $KEYCLOAK_DIST keycloak-$VERSION

cd $WORK_DIR
log_info "Cleanup temp directory..."
rm -rf $TMP
log_info "Done."
