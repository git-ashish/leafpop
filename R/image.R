#' Create HTML strings for popups
#'
#' @description
#' Create HTML strings for \code{popup} images used as input for
#' \code{mapview} or \code{leaflet}.
#'
#' @param img A character \code{vector} of file path(s) or
#' web-URL(s) to any sort of image file(s).
#' @param src Whether the source is "local" (i.e. valid file path(s)) or
#' "remote" (i.e. valid URL(s)).
#' @param embed whether to embed the (local) images in the popup html as
#' base64 ecoded. Set this to TRUE if you want to save and share your map, unless
#' you want render many images, then set to FALSE and make sure to copy ../graphs
#' when copying the map to a different location.
#' @param ... further arguments passed on to underlying methods such as
#' height and width.
#'
#' @return
#' A \code{list} of HTML strings required to create popup graphs.
#'
#' @examples
#' if (interactive()) {
#' ## remote images -----
#' ### one image
#' library(sf)
#'
#' pnt = st_as_sf(data.frame(x = 174.764474, y = -36.877245),
#'                 coords = c("x", "y"),
#'                 crs = 4326)
#'
#' img = "http://bit.ly/1TVwRiR"
#'
#' leaflet() %>%
#'   addTiles() %>%
#'   addCircleMarkers(data = pnt, popup = popupImage(img, src = "remote"))
#'
#' ### multiple file (types)
#' library(sp)
#' images = c(img,
#'             "https://upload.wikimedia.org/wikipedia/commons/9/91/Octicons-mark-github.svg",
#'             "https://www.r-project.org/logo/Rlogo.png",
#'             "https://upload.wikimedia.org/wikipedia/commons/d/d6/MeanMonthlyP.gif")
#'
#' pt4 = data.frame(x = jitter(rep(174.764474, 4), factor = 0.01),
#'                   y = jitter(rep(-36.877245, 4), factor = 0.01))
#' coordinates(pt4) = ~ x + y
#' proj4string(pt4) = "+init=epsg:4326"
#'
#' leaflet() %>%
#'   addTiles() %>%
#'   addMarkers(data = pt4, popup = popupImage(images)) # NOTE the gif animation
#'
#' ## local images -----
#' pnt = st_as_sf(data.frame(x = 174.764474, y = -36.877245),
#'                 coords = c("x", "y"), crs = 4326)
#' img = system.file("img","Rlogo.png",package="png")
#' leaflet() %>%
#'   addTiles() %>%
#'   addCircleMarkers(data = pnt, popup = popupImage(img))
#' }
#'
#' @export popupImage
#' @name popupImage
#' @rdname popup
popupImage = function(img, src = c("local", "remote"), embed = FALSE, ...) {

  if (!is.list(img)) img = as.list(img)
  fex = sapply(img, file.exists)
  srcs = sapply(fex, function(i) ifelse(i, "local", "remote"))

  pop = lapply(seq(img), function(i) {
    src = srcs[i]
    pop = switch(src,
                 local = popupLocalImage(img = img[[i]], embed = embed, ...),
                 remote = popupRemoteImage(img = img[[i]], ...))
  })

  return(pop)

}


### local images -----
popupLocalImage = function(img, width = NULL, height = NULL, embed = FALSE) {

  pngs = lapply(1:length(img), function(i) {

    fl = img[[i]]

    info = strsplit(
      sf::gdal_utils(
        util = "info",
        source = fl,
        quiet = TRUE
      ),
      split = "\n"
    )
    info = unlist(lapply(info, function(i) grep(utils::glob2rx("Size is*"), i, value = TRUE)))
    cols = as.numeric(strsplit(gsub("Size is ", "", info), split = ", ")[[1]])[1]
    rows = as.numeric(strsplit(gsub("Size is ", "", info), split = ", ")[[1]])[2]
    yx_ratio = rows / cols
    xy_ratio = cols / rows

    if (is.null(height) && is.null(width)) {
      width = 300
      height = yx_ratio * width
    } else if (is.null(height)) {
      height = yx_ratio * width
    } else if (is.null(width)) {
      width = xy_ratio * height
    }

    if (embed) {
      plt64 = base64enc::base64encode(fl)
      pop = paste0("<img ",
                   " width=",
                   width,
                   " height=",
                   height,
                   " src='data:image/png;base64,", plt64, "' />")
    }

    if (!embed) {
      nm = basename(fl)
      drs = file.path(tempdir(), "graphs")
      if (!dir.exists(drs)) dir.create(drs)
      fls = file.path(drs, nm)
      invisible(file.copy(fl, file.path(drs, nm)))

      pop = paste0("<image src='../graphs/",
                   basename(img),
                   "' width=",
                   width,
                   " height=",
                   height,
                   ">")
    }

    # return(uri)
    popTemplate = system.file("templates/popup-graph.brew", package = "leafpop")
    myCon = textConnection("outputObj", open = "w")
    brew::brew(popTemplate, output = myCon)
    outputObj = outputObj
    close(myCon)

    return(paste(outputObj, collapse = ' '))
  })

  return(unlist(pngs))
  #
  #
  #
  # nm = basename(img)
  # drs = file.path(tempdir(), "graphs")
  # if (!dir.exists(drs)) dir.create(drs)
  # fls = file.path(drs, nm)
  # invisible(file.copy(img, file.path(drs, nm)))
  # rel_path = file.path("..", basename(drs), basename(img))
  #
  # # info = sapply(img, function(...) rgdal::GDALinfo(..., silent = TRUE))
  # info = sapply(img, function(...) gdalUtils::gdalinfo(...))
  # info = unlist(lapply(info, function(i) grep(glob2rx("Size is*"), i, value = TRUE)))
  # cols = as.numeric(strsplit(gsub("Size is ", "", info), split = ", ")[[1]])[1]
  # rows = as.numeric(strsplit(gsub("Size is ", "", info), split = ", ")[[1]])[2]
  # yx_ratio = rows / cols
  # xy_ratio = cols / rows
  #
  # if (missing(height) && missing(width)) {
  #   width = 300
  #   height = yx_ratio * width
  # } else if (missing(height)) height = yx_ratio * width else
  #   if (missing(width)) width = xy_ratio * height
  #
  # # maxheight = 2000
  # # width = width
  # # height = height + 5
  # pop = paste0("<image src='../graphs/",
  #              basename(img),
  #              "' width=",
  #              width,
  #              " height=",
  #              height,
  #              ">")
  #
  # popTemplate = system.file("templates/popup-graph.brew", package = "leafpop")
  # myCon = textConnection("outputObj", open = "w")
  # brew::brew(popTemplate, output = myCon)
  # outputObj = outputObj
  # close(myCon)
  #
  # return(paste(outputObj, collapse = ' '))

}


### remote images -----
popupRemoteImage = function(img, width = 300, height = "100%") {
  pop = paste0("<image src='",
               img,
               "' width=",
               width,
               " height=",
               height,
               ">")
  maxheight = 2000
  popTemplate = system.file("templates/popup-graph.brew", package = "leafpop")
  myCon = textConnection("outputObj", open = "w")
  brew::brew(popTemplate, output = myCon)
  outputObj = outputObj
  close(myCon)

  return(paste(outputObj, collapse = ' '))
}
