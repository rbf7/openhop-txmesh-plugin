FROM python:3.12-slim

# The plugin is not on PyPI; install the GitHub release wheel and verify its
# SHA-256 (published next to the wheel). To upgrade, change both ARGs.
ARG VERSION=0.1.3
ARG WHEEL_SHA256=2763f83655efe1a01fcb761adeee0cea6f76f8ce9af071b2d52aee8958c105a8
ADD https://github.com/zfouts/openhop-txmesh-plugin/releases/download/v${VERSION}/openhop_txmesh_plugin-${VERSION}-py3-none-any.whl /tmp/plugin.whl
RUN echo "${WHEEL_SHA256}  /tmp/plugin.whl" | sha256sum -c - \
 && cp /tmp/plugin.whl /tmp/openhop_txmesh_plugin-${VERSION}-py3-none-any.whl \
 && pip install --no-cache-dir /tmp/openhop_txmesh_plugin-${VERSION}-py3-none-any.whl \
 && rm -f /tmp/plugin.whl /tmp/openhop_txmesh_plugin-*.whl \
 && useradd --system --uid 15889 --create-home txmesh \
 && mkdir -p /data && chown txmesh /data

ENV PYTHONUNBUFFERED=1 \
    OPENHOP_TXMESH_STATE_DIR=/data
USER txmesh
VOLUME /data

ENTRYPOINT ["openhop-txmesh"]
CMD ["--config", "/config/config.json"]
