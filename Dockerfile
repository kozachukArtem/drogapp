# ================================
# 1️⃣ Етап збірки (builder)
# ================================
FROM alpine:3.20 AS builder

# Встановлюємо пакети для збірки
RUN apk add --no-cache \
    cmake g++ git make openssl-dev sqlite-dev zlib-dev jsoncpp-dev util-linux-dev

# Клонуємо Drogon з підмодулями
RUN git clone --recursive https://github.com/drogonframework/drogon.git /tmp/drogon \
 && cd /tmp/drogon \
 && cmake -B build -DCMAKE_BUILD_TYPE=Release \
 && cmake --build build -j$(nproc) --target install \
 && rm -rf /tmp/drogon

# Копіюємо свій проєкт
WORKDIR /app
COPY . .

# Збираємо
RUN rm -rf build \
 && cmake -B build -DCMAKE_BUILD_TYPE=Release \
 && cmake --build build -j$(nproc)

# ================================
# 2️⃣ Етап виконання (runtime)
# ================================
FROM alpine:3.20

# Мінімальний набір бібліотек для запуску
RUN apk add --no-cache \
    openssl sqlite zlib jsoncpp util-linux

WORKDIR /app

# Копіюємо тільки потрібне
COPY --from=builder /app/build/drogapp03 ./drogapp03
COPY --from=builder /app/config.json ./config.json
COPY --from=builder /app/index.html ./index.html
COPY --from=builder /app/views ./views
COPY --from=builder /app/uploads ./uploads

# Відкриваємо порт
EXPOSE 8080

# Запуск
CMD ["./drogapp03", "-c", "/app/config.json"]