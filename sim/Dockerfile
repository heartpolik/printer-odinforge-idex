# Linux runtime for Klipper batch-mode tests. Mirrors the printer's klippy-env (Debian bookworm, Python 3.11).
FROM python:3.11-slim-bookworm
RUN apt-get update && apt-get install -y --no-install-recommends gcc libc6-dev libffi-dev && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir \
      Jinja2==2.11.3 MarkupSafe==1.1.1 cffi==1.15.1 greenlet==2.0.2 pyserial==3.4 python-can==3.3.4 \
      msgspec==0.19.0 numpy==2.2.2 scipy==1.14.1 matplotlib==3.9.4 PyWavelets==1.6.0 zstandard==0.23.0 \
      GitPython==3.1.41
RUN useradd -m -u 1000 biqu
USER biqu
