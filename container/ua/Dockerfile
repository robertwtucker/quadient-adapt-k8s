FROM redhat/ubi9

LABEL "provider"="Quadient Group AG"

ARG ADAPT_PATH=/opt/adapt
ARG USER_ID=1001
ARG GROUP_ID=0

ADD --chown=${USER_ID}:${GROUP_ID} InspireAdapt_adeptua_2.4.1.22_api_7.21.4.159_RedHat(Ootpa)-64.tar ${ADAPT_PATH}
COPY etc/ ${ADAPT_PATH}/etc/
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENV PATH=${ADAPT_PATH}/ua:${PATH}
ENV LD_LIBRARY_PATH=${ADAPT_PATH}/ua

RUN ln -s ${ADAPT_PATH}/InspireAdapt_2.4.1.22_64 ${ADAPT_PATH}/ua && \
    groupadd -f -g ${GROUP_ID} quadient && \
    useradd --no-user-group --uid ${USER_ID} --gid ${GROUP_ID} --home ${ADAPT_PATH} --shell /sbin/nologin quadient && \
    mkdir -p ${ADAPT_PATH}/share && \
    chown -R ${USER_ID}:${GROUP_ID} ${ADAPT_PATH} && \
    chmod -R g=u ${ADAPT_PATH} && \
    chmod +x /usr/local/bin/entrypoint.sh

WORKDIR ${ADAPT_PATH}/ua
VOLUME ${ADAPT_PATH}/share
USER ${USER_ID}

ENTRYPOINT [ "entrypoint.sh" ]
CMD [ "share" ]
