# A dummy function: sleeps for some random time and then
# print the output
f = function(x)
{
  clock = 5 * runif(1)

  print(paste("Before sleep", x, " - siesta for ", clock))

  Sys.sleep(clock)

  print(paste("After sleep", x))

  return(x)
}
