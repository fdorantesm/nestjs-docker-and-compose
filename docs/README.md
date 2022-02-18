# Dockerizando aplicación en NestJS

Estandarizar el lanzamiento de una aplicación en ambientes de desarrollo y producción nos ayudará a despreocuparnos de instalar dependencias cada vez que queremos hacer un despliegue en un servidor, ya sea una instancia en la nube o un ambiente local.

Con Javascript no es muy común tener que hacer configuraciones extras en un servidor, sin embargo, en lenguajes como PHP es más común instalar librerías del SO, habilitar o deshabilitar configuraciones, etc.

Considero yo que la principal ventaja que tenemos al dockerizar nuestras aplicaciones es que estas correrán de la misma manera en desarrollo y en producción, en escenarios normales.

Para poder construir una imagen que pueda ser ejecutada en un servidor es necesario conocer por lo menos las bases de Docker y comprender cómo funciona.

Lo primero que debemos saber es que docker se compone por contenedores e imagenes.

Un contenedor es una “instancia” en ejecución de una imagen, y una imagen es una versión de un sistema operativo con los elementos y configuraciones necesarias para ejecutar un proyecto.

Por ejemplo, cuando nosotros ejecutamos un contenedor basado en una imagen de node, estamos ejecutando un sistema operativo linux con node previamente instalado.

Cuando nosotros modificamos dicha imagen de node agregando nuestras configuraciones estamos hablando de que se está construyendo nuestra propia imagen. Esta imagen la podemos ejecutar las veces que sean necesarias además de que podemos subirlas a un repositorio de imagenes para poder desplegarla en un servidor sin la necesidad de clonar el proyecto.

---

### **Creando un Dockerfile de desarrollo**

Lo primero que tenemos que hacer para crear nuestra imagen es basarnos en una imagen que cumpla con nuestros requerimientos, en este caso node.

```docker
# Vamos a tomar la imagen de node versión 16 como base
FROM node:16

# Debemos de establecer el directorio de trabajo
WORKDIR /app

# Y listo, iniciamos la aplicación.
ENTRYPOINT yarn start:dev
```

---

### **Creando un Dockerfile productivo**

Al igual que con el Dockerfile de desarrollo nos basaremos en la imagen de node, pero en este caso habrá algunos cambios significativos.

```docker
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
```

---

### **Iniciar un contenedor con una imagen de desarrollo**

La forma más artesanal de iniciar un contenedor con nuestra imagen es mediante el comando `docker run`, no es algo complejo pero no solo es iniciarlo. El Dockerfile copiará los archivos dentro del contenedor pero no tendremos forma de actualizarlos sin tener que compilar y levantar de nuevo el contenedor.

Para eso podríamos mapear el directorio del proyecto en el directorio de nuestra aplicación dentro del contenedor, sin embargo, a futuro quizá necesitemos más volumenes, redes, acceder a otros contenedores, etc. Por lo cual, necesitaremos más que un comando.

**Docker Compose** es una herramienta de Docker que nos permite definir y ejecutar una aplicación de contenedores múltiples, y aunque nuestra aplicación solo necesita un contenedor nos ayudará a simplificar la ejecución mediante un script y un comando.

Vamos a ello.

```docker
version: '3.8'

services:
  app:
    image: nestjs-docker:local
    container_name: nestjs-docker
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - 3000:3000
    volumes:
      - .:/app
```

Para levantar nuestra aplicación en modo de desarrollo solo tendremos que ejecutar el comando up de docker compose:

```bash
docker-compose up
```

Como pudimos ver comenzar con Docker no es muy complicado si estás acostumbrado a la terminal de unix pero tampoco estás en desventaja significativa si no la conoces. Para levantar una aplicación como esta utilizarás comandos que ya usas fuera de Docker.
