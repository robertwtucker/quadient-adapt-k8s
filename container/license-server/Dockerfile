FROM redhat/ubi9

LABEL "provider"="Quadient Group AG" \
      "port.listener"="5000"

ARG ADAPT_PATH=/opt/adapt
ARG USER_ID=1001
ARG GROUP_ID=0

ADD --chown=${USER_ID}:${GROUP_ID} cdp_licser64_1.21.0.323_RedHat6.7.tar ${ADAPT_PATH}
COPY etc/ ${ADAPT_PATH}/etc/
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENV PATH=${ADAPT_PATH}/ls:${PATH}
ENV LD_LIBRARY_PATH=${ADAPT_PATH}/ls:${LD_LIBRARY_PATH}

RUN ln -sf ${ADAPT_PATH}/cdplicenseserver64_1.21.0.323_ ${ADAPT_PATH}/ls && \
    ln -sf ${ADAPT_PATH}/etc/cdplicser.cfg ${ADAPT_PATH}/ls/cdplicser.cfg && \
    groupadd -f -g ${GROUP_ID} quadient && \
    useradd --no-user-group --uid ${USER_ID} --gid ${GROUP_ID} --home ${ADAPT_PATH} --shell /sbin/nologin quadient && \
    chown -R ${USER_ID}:${GROUP_ID} ${ADAPT_PATH} && \
    chmod -R g=u ${ADAPT_PATH} && \
    mkdir -p /var/log/adapt /var/run/adapt && \
    chown -R ${USER_ID}:${GROUP_ID} /var/log/adapt /var/run/adapt && \
    chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 5000 51984/udp
WORKDIR ${ADAPT_PATH}/ls
USER ${USER_ID}

ENTRYPOINT [ "entrypoint.sh" ]
CMD [ "cdplicser" ]
