box::use(
  data.table[rbindlist],
  fs[dir_create],
  glue[glue],
  httr2[request, req_url_query, req_perform, resp_body_json, req_proxy],
  logger[log_info, log_success, log_error],
  lubridate[with_tz, floor_date],
  readr[write_csv, write_rds],
  tibble[as_tibble],
)


#' @export
today_in_dr <- function() {
  Sys.time() |>
    with_tz(tzone = "America/Santo_Domingo") |>
    floor_date("day") |>
    as.Date()
}


#' Obtener precios de instrumentos desde CEVALDOM
#'
#' Consulta la API pública de CEVALDOM y devuelve los precios de los instrumentos
#' para una fecha específica o, si no se especifica, la fecha más reciente disponible.
#'
#' Si la variable de entorno `ENV` es igual a `"BCRD"`, la solicitud se realiza a
#' través de un proxy autenticado usando las credenciales almacenadas en las variables
#' de entorno `USER` y `PASS`.
#'
#' @param date Fecha de consulta. Puede ser un objeto `Date` o un string coercible
#'   a fecha (por ejemplo, `"2026-02-14"`). Si es `NULL`, devuelve los precios más
#'   recientes disponibles.
#'
#' @return Un `tibble` con los precios de los instrumentos. Las columnas dependen de la
#'   respuesta de la API de CEVALDOM, pero típicamente incluyen identificadores del
#'   instrumento, precios y fechas.
#'
#' @details
#' La función realiza una solicitud GET al endpoint:
#' `https://www.cevaldom.com/api/cevaldom/fetch-prices`
#'
#' Si se especifica una fecha, se envía como parámetro de consulta `fixedDate`
#' en formato `"YYYY-MM-DD"`.
#'
#' @examples
#' \dontrun{
#' # Obtener precios más recientes
#' fetch_cevaldom_prices()
#'
#' # Obtener precios para una fecha específica
#' fetch_cevaldom_prices("2026-02-14")
#'
#' # Usando un objeto Date
#' fetch_cevaldom_prices(Sys.Date() - 1)
#' }
#'
#' @export
fetch_cevaldom_prices <- function(date = NULL) {
  req <- request("https://www.cevaldom.com/api/cevaldom/fetch-prices")

  if (Sys.getenv("ENV") == "BCRD") {

    req <- req |>
      req_proxy(
        url = Sys.getenv("PROXY"),
        username = Sys.getenv("USER"),
        password = Sys.getenv("PASS")
      )
  }

  if (!is.null(date)) {
    req <- req |>
      req_url_query(
        fixedDate = format(as.Date(date), "%Y-%m-%d")
      )
  }

  req |>
    req_perform() |>
    resp_body_json() |>
    rbindlist(fill = TRUE) |>
    as_tibble()
}

#' Ejecutar workflow de descarga y persistencia de precios de CEVALDOM
#'
#' Esta función descarga los precios desde CEVALDOM y los guarda en formatos
#' CSV y RDS. Está diseñada para ejecutarse en entornos automatizados como
#' GitHub Actions, con logging estructurado y manejo explícito de errores.
#'
#' @param date Fecha de referencia. Si es NULL, usa la fecha actual en República Dominicana.
#' @param dir_csv Directorio donde guardar el CSV.
#' @param dir_rds Directorio donde guardar el RDS.
#'
#' @return Invisiblemente, un tibble con los precios descargados.
#' @export
run_cevaldom_prices_workflow <- function(
    date = today_in_dr(),
    dir_csv = "data/csv",
    dir_rds = "data/rds"
) {

  tryCatch({
    
    log_info("Fetching prices as of {date}")
    
    prices <- fetch_cevaldom_prices()
    
    if (is.null(prices) || nrow(prices) == 0) {
      stop("No prices returned from CEVALDOM")
    }
    
    log_success("Prices downloaded correctly: {nrow(prices)} rows")
    
    dir_create(dir_csv)
    dir_create(dir_rds)
    
    path_csv <- glue("{dir_csv}/{date}.csv")
    path_rds <- glue("{dir_rds}/{date}.rds")
    
    log_info("Writing CSV to {path_csv}")
    write_csv(prices, path_csv)
    
    log_info("Writing RDS to {path_rds}")
    write_rds(prices, path_rds)
    
    log_success("Workflow completed successfully")
    
    invisible(prices)
    
  }, error = function(e) {
    
    log_error("Workflow failed: {conditionMessage(e)}")
    
    quit(status = 1)
    
  })
}
