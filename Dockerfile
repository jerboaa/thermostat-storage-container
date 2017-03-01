FROM centos/s2i-base-centos7
# Thermostat Storage Builder Image.
#
# Environment:
#  * $THERMOSTAT_AGENT_USERNAMES   - User name(s) for thermostat agents to use
#                                    for connecting to storage.
#  * $THERMOSTAT_AGENT_PASSWORDS   - Password(s) for thermostat agents to use
#                                    for connecting to storage.
#  * $THERMOSTAT_CLIENT_USERNAMES  - User name(s) for thermostat clients to
#                                    use for connecting to storage
#  * $THERMOSTAT_CLIENT_PASSWORDS  - Password(s) for thermostat clients to
#                                    use for connecting to storage
#  * $MONGO_USERNAME               - User name to connect to the mongodb backend
#  * $MONGO_PASSWORD               - Password to connect to the mongodb backend
#  * $MONGO_URL                    - The mongodb url to connect to

ENV THERMOSTAT_VERSION=HEAD
ENV APP_USER=default

LABEL io.k8s.description="A monitoring and serviceability tool for OpenJDK." \
      io.k8s.display-name="Thermostat Storage"

ENV THERMOSTAT_HOME /opt/app-root/thermostat
ENV USER_THERMOSTAT_HOME /opt/app-root/.thermostat

EXPOSE 8080

# Install s2i build scripts
COPY ./s2i/bin/ ${STI_SCRIPTS_PATH}

# Ensure THERMOSTAT_HOME (and parents) exist
RUN mkdir -p ${THERMOSTAT_HOME}

RUN yum install -y centos-release-scl-rh && \
    yum-config-manager --enable centos-sclo-rh-testing && \
    yum install -y --setopt=tsflags=nodocs --enablerepo=centosplus \
    nss_wrapper rh-maven33 libsecret-devel make \
    gcc gtk2-devel autoconf automake libtool && \
    yum erase -y java-1.8.0-openjdk-headless && \
    yum clean all -y
    
COPY thermostat-user-home-config ${USER_THERMOSTAT_HOME}
COPY contrib /opt/app-root

# Ensure any UID can read/write to files in /opt/app-root
RUN chown -R default:0 /opt/app-root && \
    find /opt/app-root -type d -exec chmod g+rwx '{}' \; && \
    find /opt/app-root -type f -exec chmod g+rw '{}' \;

WORKDIR ${HOME}

ADD usr /usr

# Remove any potential Hotspot perf data files
RUN rm -rf /tmp/hsperfdata_*

USER 1001

# Get prefix path and path to scripts rather than hard-code them in scripts
ENV CONTAINER_SCRIPTS_PATH=/usr/share/container-scripts/thermostat \
    ENABLED_COLLECTIONS=rh-maven33

# When bash is started non-interactively, to run a shell script, for example it
# looks for this variable and source the content of this file. This will enable
# the SCL for all scripts without need to do 'scl enable'.
ENV BASH_ENV=${CONTAINER_SCRIPTS_PATH}/scl_enable \
    ENV=${CONTAINER_SCRIPTS_PATH}/scl_enable \
    PROMPT_COMMAND=". ${CONTAINER_SCRIPTS_PATH}/scl_enable"

ENTRYPOINT ["container-entrypoint"]
CMD [ "run-thermostat-storage" ]
