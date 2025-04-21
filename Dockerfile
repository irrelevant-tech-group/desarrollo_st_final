# Usa la versión de Python que necesites
FROM python:3.11-slim

# Define el directorio de trabajo dentro del contenedor
WORKDIR /code

# Instalar dependencias del sistema necesarias para Playwright y Selenium
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    wget \
    gnupg \
    unzip \
    xvfb \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libdbus-1-3 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Instalar Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Copia los archivos de dependencias primero para optimizar caché
COPY ./requirements.txt /code/requirements.txt

# Fix vulnerabilities
RUN pip install --upgrade setuptools

# Instala las dependencias
RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

# Instalar los navegadores de Playwright
RUN playwright install chromium
RUN playwright install-deps

# Copia el resto de los archivos del proyecto
COPY . .

# Define la variable de entorno FLASK_APP
ENV FLASK_APP=carros_ui.py

# Expone el puerto para Gunicorn
EXPOSE 8000

# Comando para ejecutar la aplicación con Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "--threads", "2", "--timeout", "120", "--max-requests", "1000", "--max-requests-jitter", "50", "--worker-class", "sync", "carros_ui:app"]
