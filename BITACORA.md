# Bitácora · Taller IaC con Terraform · Grupo 3

**Curso:** Arquitectura de Software II · 2026-2 · Tema VII: Infraestructura como Código

**Integrantes**

- Sofía Giraldo González
- Carlos Augusto Aranzazu
- Miguel Ángel Rodríguez

## Rotación de roles

Con 3 integrantes, Navegante y Bitácora los asume la misma persona.

| Fase | Operador/a | Navegante | Revisor/a del plan | Bitácora |
|---|---|---|---|---|
| 0 y 1 | Miguel Ángel Rodríguez | Sofía Giraldo González | Carlos Augusto Aranzazu | Sofía Giraldo González |
| 2 | Sofía Giraldo González | Carlos Augusto Aranzazu | Miguel Ángel Rodríguez | Carlos Augusto Aranzazu |
| 3 | Carlos Augusto Aranzazu | Miguel Ángel Rodríguez | Sofía Giraldo González | Miguel Ángel Rodríguez |
| 4 | Miguel Ángel Rodríguez | Sofía Giraldo González | Carlos Augusto Aranzazu | Sofía Giraldo González |
| 5 | Sofía Giraldo González | Carlos Augusto Aranzazu | Miguel Ángel Rodríguez | Carlos Augusto Aranzazu |
| 6 | Carlos Augusto Aranzazu | Miguel Ángel Rodríguez | Sofía Giraldo González | Miguel Ángel Rodríguez |
| 7 | Miguel Ángel Rodríguez | Sofía Giraldo González | Carlos Augusto Aranzazu | Sofía Giraldo González |
| 8 | Sofía Giraldo González | Carlos Augusto Aranzazu | Miguel Ángel Rodríguez | Carlos Augusto Aranzazu |
| 9 | Carlos Augusto Aranzazu | Miguel Ángel Rodríguez | Sofía Giraldo González | Miguel Ángel Rodríguez |

---

## Fase 0 · Preparación del entorno

### Evidencias

```text
$ terraform -version
Terraform v1.17.1
on windows_amd64
```

```text
$ docker version
Client:
 Version:           28.1.1
 API version:       1.49
 Go version:        go1.23.8
 Git commit:        4eba377
 Built:             Fri Apr 18 09:53:24 2025
 OS/Arch:           windows/amd64
 Context:           desktop-linux

Server: Docker Desktop 4.41.2 (191736)
 Engine:
  Version:          28.1.1
  API version:      1.49 (minimum version 1.24)
  Go version:       go1.23.8
```

```text
$ git --version
git version 2.49.0.windows.1

$ docker pull nginx:1.27-alpine && docker pull nginx:1.28-alpine && docker pull postgres:17-alpine
docker.io/library/nginx:1.27-alpine
docker.io/library/nginx:1.28-alpine
docker.io/library/postgres:17-alpine
```

### Respuestas

Esta fase no tiene preguntas. Se creó el repositorio con `.gitignore`, la carpeta `infra/` y esta bitácora.

---

## Fase 1 · Arranque: hacerlo a mano

### Evidencias

```text
$ docker run -d --name clickops-g3 -p 8090:80 nginx:1.27-alpine
2aebb55738153df04a142868d565a7277ac33ebe7d906c0497695f25678a0e8f

$ curl -s http://localhost:8090 | grep -o '<title>.*</title>'
<title>Welcome to nginx!</title>
```

Repetir exactamente el mismo comando:

```text
$ docker run -d --name clickops-g3 -p 8090:80 nginx:1.27-alpine
docker: Error response from daemon: Conflict. The container name "/clickops-g3" is already in use by container "2aebb55738153df04a142868d565a7277ac33ebe7d906c0497695f25678a0e8f". You have to remove (or rename) that container to be able to reuse that name.
```

Otro nombre, mismo puerto:

```text
$ docker run -d --name clickops-g3-2 -p 8090:80 nginx:1.27-alpine
4fa3a8b558c791bfc229c1c8cb4d0e33b3f39229988af6cab94a360f9a2906b8
docker: Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint clickops-g3-2 (...): Bind for 0.0.0.0:8090 failed: port is already allocated
```

Docker alcanzó a crear el contenedor `clickops-g3-2` (imprimió su ID), pero no pudo arrancarlo: quedó creado y detenido.

```text
$ docker rm -f clickops-g3 clickops-g3-2
clickops-g3
clickops-g3-2

$ docker ps -a --filter name=clickops
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

**El mismo objetivo de dos formas**

Imperativo (pasos en orden):

1. Descargar la imagen `nginx:1.27-alpine`.
2. Crear un contenedor llamado `clickops-g3` con esa imagen.
3. Publicar el puerto 80 del contenedor en el 8090 del equipo.
4. Arrancar el contenedor en segundo plano.

Declarativo (resultado deseado):

> «Quiero un contenedor `clickops-g3` con nginx 1.27 respondiendo en el puerto 8090.»

### Respuestas

1. **Error del segundo `docker run`.** `Conflict. The container name "/clickops-g3" is already in use`. Un comando imperativo no es idempotente: ejecuta la acción cada vez sin mirar si el resultado ya existe, así que repetirlo no da «lo mismo» sino un error (o, con otro nombre, un contenedor a medias que choca por el puerto). Hay que revisar a mano el estado antes de cada paso.
2. **Servidor idéntico para otro grupo.** Tendríamos que contarles el comando exacto, la imagen y la versión, el nombre, el puerto y que el 8090 debe estar libre. Eso no quedó registrado en ningún lado: solo en la historia de la terminal de quien lo tecleó y en nuestra memoria.
3. **Puntos de «Por qué duele» que vivimos.** Los cuatro: fue *propenso a errores* (el conflicto de nombre y el de puerto); *imposible de reproducir igual* (el segundo intento dejó un contenedor creado pero sin arrancar); *sin historial* (nada indica quién creó qué); y *el conocimiento se va con la persona* (solo el operador sabe qué comando usó).

---

## Fase 2 · Primer despliegue

### Evidencias

_Pendiente._

### Respuestas

_Pendiente._

---

## Fase 3 · Idempotencia y estado

### Evidencias

_Pendiente._

### Respuestas

_Pendiente._

---

## Fase 4 · Drift

### Evidencias

_Pendiente._

### Respuestas

_Pendiente._

---

## Fase 5 · Flexibilidad

### Evidencias

_Pendiente._

### Respuestas

_Pendiente._

---

## Fase 6 · Módulos

### Evidencias

_Pendiente._

### Respuestas

_Pendiente._

---

## Fase 7 · State remoto y ambientes

### Evidencias

_Pendiente._

### Respuestas

_Pendiente._

---

## Fase 8 · Testing y calidad

### Evidencias

_Pendiente._

### Respuestas

_Pendiente._

---

## Fase 9 · Auditoría cruzada y cierre

### Evidencias

_Pendiente._

### Respuestas

_Pendiente._
