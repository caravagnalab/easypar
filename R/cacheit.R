cacheit = function(x, file, i) {
  if(!is.null(file))
  {
    obj = NULL
    if(file.exists(file)) obj = readRDS(file)

    new.obj = list(x)
    names(new.obj) = i
    obj = append(obj, new.obj)
    saveRDS(obj, file = file)
  }
}
