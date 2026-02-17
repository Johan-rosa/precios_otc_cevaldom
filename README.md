# Precios OTC CEVALDOM

Este proyecto descarga y guarda los **precios de instrumentos financieros OTC** de CEVALDOM (República Dominicana) de forma automatizada.

El workflow está diseñado para correr **diariamente** mediante **GitHub Actions**, generar CSV y RDS, y mantener el historial de precios actualizado.

---

## Estructura del proyecto

```
precios_otc_cevaldom/
├─ data/
│  ├─ csv/        # Precios en formato CSV
│  └─ rds/        # Precios en formato RDS
├─ scripts/
│  ├─ workflow.R  # Función principal: run_cevaldom_prices_workflow()
│  └─ otros scripts
├─ renv.lock       # Dependencias del proyecto
├─ README.md
└─ .github/workflows/  # GitHub Actions
```

---

## Instalación

Clonar el repositorio y restaurar dependencias con `renv`:

```r
# Instalar renv si no está
install.packages("renv")

# Restaurar dependencias
renv::restore()
```

Instala `box` si no lo tienes:

```r
install.packages("box")
```

---

## Uso

### Ejecutar el workflow manualmente

```r
box::use(./scripts/workflow[run_cevaldom_prices_workflow])
run_cevaldom_prices_workflow()
```

Esto:

1. Descarga los precios desde CEVALDOM.
2. Guarda un CSV en `data/csv/`.
3. Guarda un RDS en `data/rds/`.
4. Genera commit automático con los nuevos datos.

---

### Leer CSV desde GitHub

Se puede leer cualquier CSV generado directamente desde GitHub usando la función `read_github_csv`:

```r
box::use(./utils[read_github_csv])

prices <- read_github_csv(
  user = "Johan-rosa",
  repo = "precios_otc_cevaldom",
  path = "data/csv/2026-02-17.csv"
)

head(prices)
```

> Nota: para simplificar, se usa la URL raw pública del repo.

---

## 🕒 Automatización

Se ejecuta automáticamente **todos los días a las 12:00 PM UTC** mediante GitHub Actions, gracias al workflow definido en `.github/workflows/`.

El job incluye:

* Restauración de dependencias (`renv`)
* Ejecución del workflow de precios
* Commit automático de nuevos CSV/RDS
* Push seguro usando `GITHUB_TOKEN`

---

## Referencias

* [CEVALDOM](https://www.cevaldom.com/) – API pública de precios de instrumentos financieros.

---

## 📄 Licencia

Este proyecto está bajo MIT License.
