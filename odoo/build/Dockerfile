FROM odoo:18

USER root

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
        python3-pymysql \
        python3-pyproj \
        python3-prometheus-client \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .    
RUN pip install --break-system-packages -r requirements.txt

USER odoo
