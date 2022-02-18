# Vamos a tomar la imagen de node versión 16 como base
FROM node:16 as install
LABEL stage=install

# Debemos de establecer el directorio de trabajo
WORKDIR /src/install

# Vamos a copiar los archivos de npm para instalar las dependencias
COPY package.json .
COPY yarn.lock .

# Instalamos las dependencias...
RUN yarn install

# En un siguiente paso vamos a compilar la aplicación.
# Usamos la misma imagen como base.
FROM node:16 as compile
LABEL stage=compile

# Establecemos el directorio de trabajo.
WORKDIR /src/build

# Copiamos los archivos del paso anterior.
COPY --from=install /src/install .
# y copiamos los archivos restantes del proyecto.
COPY . .

# Compilamos e instalamos dependencias en modo producción.
RUN yarn build
RUN yarn install --production=true

# Por último, usaremos la versión alpine
FROM node:16-alpine as deploy

# Establecemos el directorio donde vivirá nuestra app
WORKDIR /app

# Copiamos los node_modules y nuestro archivo main.js
COPY --from=compile /src/build/dist/main.js index.js
COPY --from=compile /src/build/node_modules node_modules

# Y listo, ejecutamos la aplicación.
ENTRYPOINT node .
