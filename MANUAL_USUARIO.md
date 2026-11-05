# Manual de usuario de Ecommerce API

Este manual explica cómo usar la API desde Swagger UI, `curl` o cualquier
cliente HTTP.

## 1. Iniciar la aplicación

```bash
uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

Abre:

- Swagger UI: <http://localhost:8000/docs>
- ReDoc: <http://localhost:8000/redoc>
- OpenAPI JSON: <http://localhost:8000/openapi.json>

## 2. Flujo desde `/docs`

Las operaciones de escritura están protegidas. Para probarlas en Swagger:

1. Ejecuta `POST /auth/register` para crear un comprador, o `POST /auth/login`
   con un administrador ya configurado.
2. Ejecuta `GET /auth/csrf` y copia el valor de `csrf_token`.
3. En la operación que quieras ejecutar, pulsa **Try it out**, pega el valor en
   `x-csrf-token` y utiliza el cuerpo de ejemplo que muestra Swagger.
4. Pulsa **Execute**. La cookie de sesión se mantiene automáticamente mientras
   uses el mismo navegador y origen.

Un administrador se puede crear al arrancar con `BOOTSTRAP_ADMIN_EMAIL` y
`BOOTSTRAP_ADMIN_PASSWORD`. Las rutas de alta de productos, categorías y
usuarios desde el panel requieren ese rol.

## 3. Ejemplo completo con `curl`

El siguiente flujo registra un comprador, consulta el catálogo y crea una
orden de visitante. Para crear productos, inicia sesión con un administrador y
envía también el token CSRF.

```bash
BASE_URL=http://localhost:8000
COOKIE_JAR=/tmp/ecommerce-api-cookies.txt

# Registrar una cuenta. La respuesta también deja una cookie de sesión.
curl -c "$COOKIE_JAR" -b "$COOKIE_JAR" -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"name":"Ana Pérez","email":"ana@example.com","password":"Ana-password-123"}'

# Obtener el catálogo público.
curl "$BASE_URL/products/?limit=10&offset=0"

# Comprar sin cuenta; reemplaza 1 por un product_id existente.
curl -X POST "$BASE_URL/orders/guest" \
  -H "Content-Type: application/json" \
  -d '{"items":[{"product_id":1,"quantity":1}]}'
```

Para una operación protegida:

```bash
# Iniciar sesión como administrador.
curl -c "$COOKIE_JAR" -b "$COOKIE_JAR" -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"Admin-password-123"}'

# Guardar el token CSRF en una variable (requiere Python).
CSRF=$(curl -sS -b "$COOKIE_JAR" "$BASE_URL/auth/csrf" |
  python -c 'import json,sys; print(json.load(sys.stdin)["csrf_token"])')

# Crear un producto.
curl -X POST "$BASE_URL/products/" \
  -b "$COOKIE_JAR" \
  -H "Content-Type: application/json" \
  -H "x-csrf-token: $CSRF" \
  -d '{"name":"Teclado mecánico","sku":"TEC-MEC-001","price":79.99,"stock":25}'
```

## 4. Funcionalidades principales

| Funcionalidad | Endpoint | Acceso |
| --- | --- | --- |
| Registrar cuenta | `POST /auth/register` | Público |
| Iniciar/cerrar sesión | `POST /auth/login`, `POST /auth/logout` | Sesión |
| Obtener CSRF | `GET /auth/csrf` | Sesión |
| Listar catálogo paginado | `GET /products/` | Público |
| Crear producto | `POST /products/` | Administrador + CSRF |
| Actualizar producto | `PATCH /products/{product_id}` | Administrador + CSRF |
| Crear categoría | `POST /categories/` | Administrador + CSRF |
| Crear orden autenticada | `POST /orders/` | Comprador + CSRF |
| Crear orden de visitante | `POST /orders/guest` | Público |
| Consultar mis órdenes | `GET /orders/mine` | Sesión |
| Consultar historial de usuario | `GET /users/{user_id}/orders` | Propietario o administrador |

El checkout descuenta stock dentro de una transacción. Si no existe un
producto, devuelve `400`; si no hay stock suficiente, devuelve `409`; los
errores de validación del cuerpo devuelven `422`.

## 5. Errores habituales

- `401 Autenticación requerida`: inicia sesión primero.
- `403 Token CSRF inválido`: vuelve a consultar `/auth/csrf` y envía el token
  en `x-csrf-token`.
- `403 Permisos de administrador requeridos`: usa una cuenta con rol `admin`.
- `409 El SKU ya está registrado`: usa un SKU único.
- `422`: revisa los tipos, campos obligatorios y restricciones mostradas por
  Swagger.

Swagger contiene un ejemplo editable para cada cuerpo de creación y las
descripciones de acceso aparecen junto a cada operación.
