FROM redhat/ubi9

ARG ADAPT_PATH=/opt/adapt
ARG USER_ID=1001
ARG GROUP_ID=0

ADD --chown=${USER_ID}:${GROUP_ID} cdp_adeptua_1.8.1.23_api_7.21.2.11_RedHat6.7-64.tar ${ADAPT_PATH}
COPY etc/ ${ADAPT_PATH}/etc/
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENV PATH=${ADAPT_PATH}/ua:${PATH}
ENV LD_LIBRARY_PATH=${ADAPT_PATH}/ua:${LD_LIBRARY_PATH}

RUN ln -s ${ADAPT_PATH}/cdpadua_1.8.1.23_64 ${ADAPT_PATH}/ua && \
 	groupadd -f -g ${GROUP_ID} quadient && \
    useradd --no-user-group --uid ${USER_ID} --gid ${GROUP_ID} --home ${ADAPT_PATH} --shell /sbin/nologin quadient && \
 	chown -R ${USER_ID}:${GROUP_ID} ${ADAPT_PATH} && \
	chmod -R g=u ${ADAPT_PATH} && \
    chmod +x /usr/local/bin/entrypoint.sh

WORKDIR ${ADAPT_PATH}/ua
USER ${USER_ID}

ENTRYPOINT [ "entrypoint.sh" ]
