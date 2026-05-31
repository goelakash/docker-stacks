# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

# Ubuntu 24.04 (noble)
# https://hub.docker.com/_/ubuntu/tags?page=1&name=noble
ARG ROOT_IMAGE=ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

FROM $ROOT_IMAGE

LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"
ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Install all OS dependencies for the Server that starts
# but lacks all features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update --yes && \
    # - `apt-get upgrade` is run to patch known vulnerabilities in system packages
    #   as the Ubuntu base image is rebuilt too seldom sometimes (less than once a month)
    apt-get upgrade --yes && \
    apt-get install --yes --no-install-recommends \
    ca-certificates \
    curl \
    locales \
    # - `netbase` provides /etc/{protocols,rpc,services}, part of POSIX
    #   and required by various C functions like getservbyname and getprotobyname
    #   https://github.com/jupyter/docker-stacks/pull/2129
    netbase \
    sudo \
    # - `tini` is installed as a helpful container entrypoint,
    #   that reaps zombie processes and such of the actual executable we want to start
    #   See https://github.com/krallin/tini#why-tini for details
    tini && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    echo "C.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER="${NB_USER}" \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    LANGUAGE=C.UTF-8
ENV PATH="${CONDA_DIR}/bin:${PATH}" \
    HOME="/home/${NB_USER}"

# Copy a script that we will use to correct permissions after running certain commands
COPY fix-permissions /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions

# Enable prompt color in the skeleton .bashrc before creating the default NB_USER
# hadolint ignore=SC2016
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc && \
    # More information in: https://github.com/jupyter/docker-stacks/pull/2047
    # and docs: https://docs.conda.io/projects/conda/en/latest/dev-guide/deep-dives/activation.html
    echo 'eval "$(conda shell.bash hook)"' >> /etc/skel/.bashrc

# Delete existing user with UID="${NB_UID}" if it exists
# hadolint ignore=SC2046
RUN if grep -q "${NB_UID}" /etc/passwd; then \
        userdel --remove $(id -un "${NB_UID}"); \
    fi

# Create "${NB_USER}" user (`jovyan` by default) with UID="${NB_UID}" (`1000` by default) and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    useradd --no-log-init --create-home --shell /bin/bash --uid "${NB_UID}" --no-user-group "${NB_USER}" && \
    mkdir -p "${CONDA_DIR}" && \
    chown "${NB_USER}:${NB_GID}" "${CONDA_DIR}" && \
    chmod g+w /etc/passwd && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# macOS Rosetta virtualization creates junk directory which gets owned by root further up.
# It'll get re-created, but as USER runner after the next directive so hopefully should not cause permission issues.
#
# More info: https://github.com/jupyter/docker-stacks/issues/2296
RUN rm -rf "/home/${NB_USER}/.cache/"

USER ${NB_UID}


# Setup work directory for backward-compatibility
RUN mkdir "/home/${NB_USER}/work" && \
    fix-permissions "/home/${NB_USER}"

# Install pixi and use it to create the conda environment from the lockfile.
# This ensures reproducible builds with pinned dependencies.
COPY --chown="${NB_UID}:${NB_GID}" initial-condarc "${CONDA_DIR}/.condarc"
COPY --chown="${NB_UID}:${NB_GID}" pixi.toml pixi.lock /tmp/pixi-project/
WORKDIR /tmp/pixi-project
RUN set -x && \
    curl -fsSL https://pixi.sh/install.sh | bash && \
    export PATH="$HOME/.pixi/bin:$PATH" && \
    pixi install --manifest-path /tmp/pixi-project/pixi.toml && \
    cp -a /tmp/pixi-project/.pixi/envs/default/* "${CONDA_DIR}/" && \
    rm -rf /tmp/pixi-project "$HOME/.pixi" && \
    mamba list --full-name 'python' | awk 'END{sub("[^.]*$", "*", $2); print $1 " " $2}' >> "${CONDA_DIR}/conda-meta/pinned" && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Copy local files as late as possible to avoid cache busting
COPY run-hooks.sh start.sh /usr/local/bin/

# Configure container entrypoint
ENTRYPOINT ["tini", "-g", "--", "start.sh"]

USER root

# Create dirs for startup hooks
RUN mkdir /usr/local/bin/start-notebook.d && \
    mkdir /usr/local/bin/before-notebook.d

COPY 10activate-conda-env.sh /usr/local/bin/before-notebook.d/

# macOS Rosetta virtualization creates junk directory which gets owned by root further up.
# It'll get re-created, but as USER runner after the next directive so hopefully should not cause permission issues.
#
# More info: https://github.com/jupyter/docker-stacks/issues/2296
RUN rm -rf "/home/${NB_USER}/.cache/"

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}

WORKDIR "${HOME}"
